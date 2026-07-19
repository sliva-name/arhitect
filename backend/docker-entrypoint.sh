#!/bin/sh

# Get user ID and group ID from environment (default to 1000)
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}

# Set or replace a KEY=value in .env (handles commented Laravel defaults like "# DB_HOST=")
set_env() {
    key="$1"
    value="$2"
    if [ ! -f .env ]; then
        return 1
    fi
    if grep -qE "^#?[[:space:]]*${key}=" .env; then
        sed -i "s|^#[[:space:]]*${key}=.*|${key}=${value}|; s|^${key}=.*|${key}=${value}|" .env
    else
        printf '%s=%s\n' "$key" "$value" >> .env
    fi
}

run_artisan() {
    if [ "$(id -u)" = "0" ] && id -u appuser >/dev/null 2>&1; then
        gosu appuser php artisan "$@"
    else
        php artisan "$@"
    fi
}

configure_docker_env() {
    echo "Configuring .env for Docker (PostgreSQL/Redis)..."
    set_env APP_URL "${APP_URL:-http://api.localhost:8080}"
    set_env DB_CONNECTION "${DB_CONNECTION:-pgsql}"
    set_env DB_HOST "${DB_HOST:-db}"
    set_env DB_PORT "${DB_PORT:-5432}"
    set_env DB_DATABASE "${DB_DATABASE:-laravel}"
    set_env DB_USERNAME "${DB_USERNAME:-laravel}"
    set_env DB_PASSWORD "${DB_PASSWORD:-secret}"
    set_env REDIS_HOST "${REDIS_HOST:-redis}"
    set_env REDIS_PORT "${REDIS_PORT:-6379}"
}

wait_for_database() {
    echo "Waiting for database..."
    i=0
    while [ "$i" -lt 30 ]; do
        if run_artisan db:show --database=pgsql >/dev/null 2>&1; then
            echo "Database is ready."
            return 0
        fi
        # Fallback: PDO connect without relying on artisan db:show
        if php -r "
            try {
                new PDO(
                    sprintf('pgsql:host=%s;port=%s;dbname=%s', getenv('DB_HOST') ?: 'db', getenv('DB_PORT') ?: '5432', getenv('DB_DATABASE') ?: 'laravel'),
                    getenv('DB_USERNAME') ?: 'laravel',
                    getenv('DB_PASSWORD') ?: 'secret'
                );
                exit(0);
            } catch (Throwable \$e) {
                exit(1);
            }
        " 2>/dev/null; then
            echo "Database is ready."
            return 0
        fi
        i=$((i + 1))
        sleep 2
    done
    echo "ERROR: database did not become ready in time"
    return 1
}

run_migrations() {
    echo "Running database migrations..."
    if ! run_artisan migrate --force --no-interaction; then
        echo "ERROR: migrations failed"
        return 1
    fi
    echo "Migrations completed."
}

# Fix ownership of /var/www/html directory (only if running as root)
if [ "$(id -u)" = "0" ]; then
    chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true
fi

# Check if this is a Laravel project
if [ ! -f "artisan" ] || [ ! -f "bootstrap/app.php" ]; then
    echo "Initializing new Laravel project..."

    # Clean up any non-Laravel files if present
    if [ -f "composer.json" ] && [ ! -f "artisan" ]; then
        echo "Found non-Laravel project, cleaning up..."
        find . -mindepth 1 -maxdepth 1 ! -name 'vendor' ! -name '.git' ! -name '.env' -exec rm -rf {} + 2>/dev/null || true
    fi

    # Run composer (already running as appuser if user: appuser is set in docker-compose)
    if [ "$(id -u)" = "0" ] && id -u appuser >/dev/null 2>&1; then
        gosu appuser composer create-project laravel/laravel /tmp/laravel --no-interaction --prefer-dist || exit 1
    else
        composer create-project laravel/laravel /tmp/laravel --no-interaction --prefer-dist || exit 1
    fi

    # Copy Laravel files to working directory
    cp -a /tmp/laravel/. ./ || exit 1
    rm -rf /tmp/laravel

    # Ensure Laravel directories exist with correct permissions
    if [ "$(id -u)" = "0" ]; then
        mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
        mkdir -p bootstrap/cache
        mkdir -p public/vendor
        chown -R ${USER_ID}:${GROUP_ID} storage bootstrap/cache public/vendor 2>/dev/null || true
        chmod -R 775 storage bootstrap/cache 2>/dev/null || true
        chmod -R 775 public/vendor 2>/dev/null || true
    fi

    # Setup environment
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env || exit 1
        else
            # Fallback: create minimal .env
            cat > .env <<'EOF'
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://api.localhost:8080

DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret

REDIS_HOST=redis
REDIS_PORT=6379
EOF
        fi
        configure_docker_env
        run_artisan key:generate --no-interaction || exit 1
    else
        configure_docker_env
    fi

    # Install dev tools
    # Run composer (already running as appuser if user: appuser is set in docker-compose)
    if [ "$(id -u)" = "0" ] && id -u appuser >/dev/null 2>&1; then
        gosu appuser composer require --dev laravel/pint phpstan/phpstan larastan/larastan --no-interaction || exit 1
    else
        composer require --dev laravel/pint phpstan/phpstan larastan/larastan --no-interaction || exit 1
    fi

    # Create storage symlink if it doesn't exist
    if [ ! -L "public/storage" ]; then
        run_artisan storage:link || true
    fi

    # Create Pint config
    cat > pint.json <<'EOF'
{
    "preset": "psr12"
}
EOF

    # Create PHPStan config
    cat > phpstan.neon <<'EOF'
includes:
    - vendor/larastan/larastan/extension.neon
    - vendor/nesbot/carbon/extension.neon

parameters:

    paths:
        - app/

    # Level 10 is the highest level
    level: 5

#    ignoreErrors:
#        - '#PHPDoc tag @var#'
#
#    excludePaths:
#        - ./*/*/FileToBeExcluded.php
EOF

    # Create PHPUnit config with test reports
    # Ensure tests/reports directory exists
    mkdir -p tests/reports

    # Update phpunit.xml if it exists, or create a custom one
    if [ -f "phpunit.xml" ]; then
        # Backup original and update it
        cp phpunit.xml phpunit.xml.bak
    fi

    # Create/update phpunit.xml with report configuration
    cat > phpunit.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         cacheDirectory=".phpunit.cache"
         executionOrder="depends,defects"
         failOnRisky="true"
         failOnWarning="true"
         processIsolation="false"
         stopOnFailure="false">
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>app</directory>
        </include>
    </source>
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="CACHE_DRIVER" value="array"/>
        <env name="DB_DATABASE" value=":memory:"/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
    </php>
    <logging>
        <junit outputFile="tests/reports/junit.xml"/>
        <coverage>
            <report>
                <cobertura outputFile="tests/reports/cobertura.xml"/>
            </report>
        </coverage>
    </logging>
</phpunit>
EOF

    echo "Laravel project initialized successfully!"

    # Fix ownership after initialization (only if running as root)
    if [ "$(id -u)" = "0" ]; then
        chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true
    fi
else
    echo "Laravel project detected, skipping initialization..."

    # Ensure tests/reports directory exists for existing projects
    mkdir -p tests/reports
    if [ "$(id -u)" = "0" ]; then
        chown -R ${USER_ID}:${GROUP_ID} tests/reports 2>/dev/null || true
    fi
fi

# Install/update dependencies if needed
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "Installing dependencies..."
    # Run composer (already running as appuser if user: appuser is set in docker-compose)
    if [ "$(id -u)" = "0" ] && id -u appuser >/dev/null 2>&1; then
        gosu appuser composer install --no-interaction --prefer-dist || exit 1
    else
        composer install --no-interaction --prefer-dist || exit 1
    fi

    # Ensure directories exist and have correct permissions after composer install
    if [ "$(id -u)" = "0" ]; then
        mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
        mkdir -p bootstrap/cache
        mkdir -p public/vendor
        chown -R ${USER_ID}:${GROUP_ID} storage bootstrap/cache public/vendor 2>/dev/null || true
        chmod -R 775 storage bootstrap/cache 2>/dev/null || true
        chmod -R 775 public/vendor 2>/dev/null || true
    fi
fi

# Ensure .env exists and points at Docker services
if [ ! -f ".env" ]; then
    echo "Setting up environment..."
    if [ -f ".env.example" ]; then
        cp .env.example .env || exit 1
    else
        cat > .env <<'EOF'
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://api.localhost:8080

DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret

REDIS_HOST=redis
REDIS_PORT=6379
EOF
    fi
    configure_docker_env
    run_artisan key:generate --no-interaction || exit 1

    if [ "$(id -u)" = "0" ]; then
        chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true
    fi
else
    configure_docker_env
fi

# Ensure APP_KEY exists
if ! grep -qE '^APP_KEY=base64:' .env; then
    run_artisan key:generate --no-interaction || exit 1
fi

# Ensure Laravel directories exist and have correct permissions
if [ "$(id -u)" = "0" ]; then
    # Create necessary Laravel directories if they don't exist
    mkdir -p storage/framework/cache
    mkdir -p storage/framework/sessions
    mkdir -p storage/framework/views
    mkdir -p storage/logs
    mkdir -p bootstrap/cache
    mkdir -p public/vendor

    # Fix ownership of all files and directories
    chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true

    # Ensure directories are writable
    chmod -R 775 storage bootstrap/cache 2>/dev/null || true
    chmod -R 775 public/vendor 2>/dev/null || true
fi

# Wait for Postgres, then migrate
wait_for_database || exit 1
run_migrations || exit 1

# Switch to appuser if running as root and appuser exists, otherwise run as current user
if [ "$(id -u)" = "0" ] && id -u appuser >/dev/null 2>&1; then
    exec gosu appuser "$@"
else
    exec "$@"
fi
