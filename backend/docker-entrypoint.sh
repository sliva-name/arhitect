#!/bin/sh

# Check if this is a Laravel project
if [ ! -f "artisan" ] || [ ! -f "bootstrap/app.php" ]; then
    echo "Initializing new Laravel project..."
    
    # Clean up any non-Laravel files if present
    if [ -f "composer.json" ] && [ ! -f "artisan" ]; then
        echo "Found non-Laravel project, cleaning up..."
        find . -mindepth 1 -maxdepth 1 ! -name 'vendor' ! -name '.git' ! -name '.env' -exec rm -rf {} + 2>/dev/null || true
    fi
    
    composer create-project laravel/laravel /tmp/laravel --no-interaction --prefer-dist || exit 1
    
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
        php artisan key:generate --no-interaction || exit 1
    fi
    
    # Install dev tools
    composer require --dev laravel/pint phpstan/phpstan nunomaduro/larastan --no-interaction || exit 1

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
    checkMissingIterableValueType: false
EOF

    echo "Laravel project initialized successfully!"
else
    echo "Laravel project detected, skipping initialization..."
fi

# Install/update dependencies if needed
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "Installing dependencies..."
    composer install --no-interaction --prefer-dist || exit 1
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
    php artisan key:generate --no-interaction || exit 1
fi

exec "$@"
