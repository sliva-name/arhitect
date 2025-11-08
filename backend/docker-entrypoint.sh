#!/bin/sh

# Get user ID and group ID from environment (default to 1000)
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}

# Fix ownership of /var/www/html directory
chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true

# Check if this is a Laravel project
if [ ! -f "artisan" ] || [ ! -f "bootstrap/app.php" ]; then
    echo "Initializing new Laravel project..."
    
    # Clean up any non-Laravel files if present
    if [ -f "composer.json" ] && [ ! -f "artisan" ]; then
        echo "Found non-Laravel project, cleaning up..."
        find . -mindepth 1 -maxdepth 1 ! -name 'vendor' ! -name '.git' ! -name '.env' -exec rm -rf {} + 2>/dev/null || true
    fi
    
    # Run composer as appuser if it exists, otherwise as root
    if id -u appuser >/dev/null 2>&1; then
        gosu appuser composer create-project laravel/laravel /tmp/laravel --no-interaction --prefer-dist || exit 1
    else
        composer create-project laravel/laravel /tmp/laravel --no-interaction --prefer-dist || exit 1
    fi
    
    # Copy Laravel files to working directory
    cp -a /tmp/laravel/. ./ || exit 1
    rm -rf /tmp/laravel
    
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
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
EOF
        fi
        # Run artisan as appuser if it exists, otherwise as root
        if id -u appuser >/dev/null 2>&1; then
            gosu appuser php artisan key:generate --no-interaction || exit 1
        else
            php artisan key:generate --no-interaction || exit 1
        fi
    fi
    
    # Install dev tools
    # Run composer as appuser if it exists, otherwise as root
    if id -u appuser >/dev/null 2>&1; then
        gosu appuser composer require --dev laravel/pint phpstan/phpstan nunomaduro/larastan --no-interaction || exit 1
    else
        composer require --dev laravel/pint phpstan/phpstan nunomaduro/larastan --no-interaction || exit 1
    fi

    # Create Pint config
    cat > pint.json <<'EOF'
{
    "preset": "laravel"
}
EOF

    # Create PHPStan config
    cat > phpstan.neon <<'EOF'
includes:
    - ./vendor/nunomaduro/larastan/extension.neon

parameters:
    paths:
        - app
        - config
        - database
        - routes
    level: 5
    tmpDir: .phpstan-cache
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
    
    # Fix ownership after initialization
    chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true
else
    echo "Laravel project detected, skipping initialization..."
    
    # Ensure tests/reports directory exists for existing projects
    mkdir -p tests/reports
    chown -R ${USER_ID}:${GROUP_ID} tests/reports 2>/dev/null || true
fi

# Install/update dependencies if needed
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "Installing dependencies..."
    # Run composer as appuser if it exists, otherwise as root
    if id -u appuser >/dev/null 2>&1; then
        gosu appuser composer install --no-interaction --prefer-dist || exit 1
    else
        composer install --no-interaction --prefer-dist || exit 1
    fi
fi

# Ensure .env exists
if [ ! -f ".env" ]; then
    echo "Setting up environment..."
    if [ -f ".env.example" ]; then
        cp .env.example .env || exit 1
    else
        # Fallback: create minimal .env
        cat > .env <<'EOF'
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
EOF
    fi
    # Run artisan as appuser if it exists, otherwise as root
    if id -u appuser >/dev/null 2>&1; then
        gosu appuser php artisan key:generate --no-interaction || exit 1
    else
        php artisan key:generate --no-interaction || exit 1
    fi
    
    # Fix ownership after .env setup
    chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true
fi

# Fix ownership before starting
chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true

# Switch to appuser if it exists, otherwise run as root
if id -u appuser >/dev/null 2>&1; then
    exec gosu appuser "$@"
else
    exec "$@"
fi
