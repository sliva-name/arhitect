#!/bin/sh

# Check if this is a Nuxt project
if [ ! -f "nuxt.config.ts" ] && [ ! -f "nuxt.config.js" ]; then
    echo "Initializing new Nuxt project..."
    
    # Clean up any non-Nuxt files if present
    if [ -f "package.json" ] && [ ! -f "nuxt.config.ts" ] && [ ! -f "nuxt.config.js" ]; then
        echo "Found non-Nuxt project, cleaning up..."
        find . -mindepth 1 -maxdepth 1 ! -name 'node_modules' ! -name '.git' -exec rm -rf {} + 2>/dev/null || true
    fi
    
    npx nuxi@latest init /tmp/nuxt --no-install --force || exit 1
    
    # Copy Nuxt files to working directory
    cp -a /tmp/nuxt/. ./ || exit 1
    rm -rf /tmp/nuxt
    
    npm install || exit 1
    
    echo "Nuxt project initialized successfully!"
else
    echo "Nuxt project detected, skipping initialization..."
    
    # Verify dev script exists in package.json
    if [ -f "package.json" ]; then
        if ! grep -q '"dev"' package.json; then
            echo "Warning: 'dev' script not found in package.json"
            echo "This might not be a Nuxt project. Reinitializing..."
            
            # Backup and reinitialize
            mv package.json package.json.backup 2>/dev/null || true
            npx nuxi@latest init /tmp/nuxt --no-install --force || exit 1
            cp -a /tmp/nuxt/. ./ || exit 1
            rm -rf /tmp/nuxt
            npm install || exit 1
        fi
    fi
fi

# Install/update dependencies if needed
if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
    echo "Installing dependencies..."
    npm install || exit 1
fi

exec "$@"
