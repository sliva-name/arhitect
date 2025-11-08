#!/bin/sh
set -e

if [ ! -f "package.json" ]; then
    echo "🚀 Initializing new Nuxt project..."
    npx nuxi@latest init . --no-install --force
    
    npm install
    
    echo "✅ Nuxt project initialized successfully!"
fi

if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

exec "$@"
