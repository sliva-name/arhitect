#!/bin/sh

if [ ! -f "composer.json" ]; then
    echo "Initializing new Laravel project..."
    composer create-project laravel/laravel . --no-interaction --prefer-dist || exit 1
    
    if [ ! -f ".env" ]; then
        cp .env.example .env || exit 1
        php artisan key:generate --no-interaction || exit 1
    fi
    
    composer require --dev laravel/pint phpstan/phpstan nunomaduro/larastan --no-interaction || exit 1

    cat > pint.json <<'EOF'
{
    "preset": "laravel"
}
EOF

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
fi

if [ ! -d "vendor" ]; then
    echo "Installing dependencies..."
    composer install --no-interaction --prefer-dist || exit 1
fi

if [ ! -f ".env" ]; then
    echo "Setting up environment..."
    cp .env.example .env || exit 1
    php artisan key:generate --no-interaction || exit 1
fi

exec "$@"
