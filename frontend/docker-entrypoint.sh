#!/bin/sh

if [ ! -f "package.json" ]; then
    echo "Initializing new Nuxt project..."
    npx nuxi@latest init . --no-install --force || exit 1
    
    npm install || exit 1
    
    echo "Nuxt project initialized successfully!"
fi

if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install || exit 1
fi

exec "$@"
