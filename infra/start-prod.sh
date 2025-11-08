#!/bin/bash

echo "Starting production environment..."

cd "$(dirname "$0")"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

# Check if PROD_DOMAIN is set
if ! grep -q "PROD_DOMAIN=" .env || grep -q "^#.*PROD_DOMAIN" .env; then
    echo "ERROR: PROD_DOMAIN not set in .env!"
    echo "Please set PROD_DOMAIN=yourdomain.com in .env"
    exit 1
fi

# Create letsencrypt directory
mkdir -p letsencrypt
chmod 600 letsencrypt

# Build and start services
echo "Building production images..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

echo "Starting services..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

echo ""
echo "========================================"
echo "Production environment started!"
echo "========================================"
echo ""
echo "Access points:"
echo "  - Frontend:  https://$(grep PROD_DOMAIN .env | cut -d'=' -f2)"
echo "  - Backend:   https://api.$(grep PROD_DOMAIN .env | cut -d'=' -f2)"
echo ""
echo "Check status:"
echo "  docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps"
echo ""
