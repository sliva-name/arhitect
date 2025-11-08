#!/bin/sh
set -e

if [ ! -f "composer.json" ]; then
    echo "🚀 Initializing new Laravel project..."
    composer create-project laravel/laravel . --no-interaction --prefer-dist
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        php artisan key:generate --no-interaction
    fi
    
    composer require --dev laravel/pint phpstan/phpstan nunomaduro/larastan --no-interaction

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

    echo "✅ Laravel project initialized successfully!"
fi

if [ ! -d "vendor" ]; then
    echo "📦 Installing dependencies..."
    composer install --no-interaction --prefer-dist
fi

if [ ! -f ".env" ]; then
    echo "⚙️  Setting up environment..."
    cp .env.example .env
    php artisan key:generate --no-interaction
fi

exec "$@"
