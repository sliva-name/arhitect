#!/bin/sh

# Production entrypoint for Laravel with PHP-FPM + Nginx

# Get user ID and group ID from environment (default to 1000)
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}

# Fix ownership
chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true

# Install/update dependencies if needed
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "Installing dependencies..."
    composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev || exit 1
fi

# Ensure .env exists
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found in production!"
    exit 1
fi

# Optimize Laravel for production
echo "Optimizing Laravel for production..."
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true
php artisan event:cache || true

# Fix ownership before starting
chown -R ${USER_ID}:${GROUP_ID} /var/www/html 2>/dev/null || true

# Start PHP-FPM
exec php-fpm

