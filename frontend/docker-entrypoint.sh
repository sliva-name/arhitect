#!/bin/sh

# Get user ID and group ID from environment (default to 1000)
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}

# Fix ownership of /app directory
chown -R ${USER_ID}:${GROUP_ID} /app 2>/dev/null || true

# Check if this is a Nuxt project
if [ ! -f "nuxt.config.ts" ] && [ ! -f "nuxt.config.js" ] && [ ! -f "nuxt.config.mjs" ]; then
    echo "Initializing new Nuxt project..."
    
    # Clean up any non-Nuxt files if present (but keep node_modules volume)
    if [ -f "package.json" ]; then
        echo "Found non-Nuxt project, cleaning up..."
        find . -mindepth 1 -maxdepth 1 ! -name 'node_modules' ! -name '.git' ! -name '.dockerignore' ! -name 'Dockerfile' ! -name 'docker-entrypoint.sh' ! -name '.gitkeep' -exec rm -rf {} + 2>/dev/null || true
    fi
    
    # Initialize Nuxt project directly in current directory
    # Note: nuxi init may return non-zero even on success, so we check files instead
    echo "Running nuxi init..."
    # Run as appuser if it exists, otherwise as root
    if id -u appuser >/dev/null 2>&1; then
        su-exec appuser npx nuxi@latest init . --no-install --force 2>&1 || true
    else
        npx nuxi@latest init . --no-install --force 2>&1 || true
    fi
    
    # Verify that nuxt.config was created
    if [ ! -f "nuxt.config.ts" ] && [ ! -f "nuxt.config.js" ] && [ ! -f "nuxt.config.mjs" ]; then
        echo "ERROR: nuxt.config file was not created after initialization"
        exit 1
    fi
    
    # Verify package.json exists
    if [ ! -f "package.json" ]; then
        echo "ERROR: package.json was not created"
        exit 1
    fi
    
    echo "Installing dependencies..."
    # Use npm ci for faster, reliable installs, fallback to npm install
    # Run as appuser if it exists, otherwise as root
    if id -u appuser >/dev/null 2>&1; then
        if ! su-exec appuser npm ci --prefer-offline --no-audit 2>/dev/null; then
            echo "npm ci failed, trying npm install..."
            if ! su-exec appuser npm install --prefer-offline --no-audit; then
                echo "ERROR: Failed to install dependencies"
                exit 1
            fi
        fi
    else
        if ! npm ci --prefer-offline --no-audit 2>/dev/null; then
            echo "npm ci failed, trying npm install..."
            if ! npm install --prefer-offline --no-audit; then
                echo "ERROR: Failed to install dependencies"
                exit 1
            fi
        fi
    fi
    
    # Verify nuxt is installed
    if [ ! -f "node_modules/.bin/nuxt" ] && [ ! -f "node_modules/nuxt/bin/nuxt.mjs" ]; then
        echo "ERROR: nuxt binary not found after installation"
        exit 1
    fi
    
    echo "Nuxt project initialized successfully!"
    
    # Fix ownership after initialization
    chown -R ${USER_ID}:${GROUP_ID} /app 2>/dev/null || true
else
    echo "Nuxt project detected, skipping initialization..."
fi

# Install/update dependencies if needed
if [ -f "package.json" ]; then
    # Check if node_modules exists and has content, or if package-lock.json is missing
    if [ ! -d "node_modules" ] || [ -z "$(ls -A node_modules 2>/dev/null)" ] || [ ! -f "package-lock.json" ]; then
        echo "Installing/updating dependencies..."
        # Run as appuser if it exists, otherwise as root
        if id -u appuser >/dev/null 2>&1; then
            if ! su-exec appuser npm install --prefer-offline --no-audit; then
                echo "ERROR: Failed to install dependencies"
                exit 1
            fi
        else
            if ! npm install --prefer-offline --no-audit; then
                echo "ERROR: Failed to install dependencies"
                exit 1
            fi
        fi
    fi
    
    # Verify package.json has dev script
    if ! grep -q '"dev"' package.json; then
        echo "WARNING: 'dev' script not found in package.json"
    fi
    
    # Fix ownership after dependency installation
    chown -R ${USER_ID}:${GROUP_ID} /app 2>/dev/null || true
fi

echo "Starting Nuxt dev server..."
# Switch to appuser if it exists, otherwise run as root
if id -u appuser >/dev/null 2>&1; then
    exec su-exec appuser "$@"
else
    exec "$@"
fi
