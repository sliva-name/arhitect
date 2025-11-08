#!/bin/bash

echo "Initializing project structure..."

cd "$(dirname "$0")"

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "Creating environment configuration from .env.example..."
        cp .env.example .env
        echo "Created .env"
        echo "Please edit .env if you need to change default values."
    else
        echo "WARNING: .env.example not found!"
        echo "Creating minimal .env..."
        cat > .env <<EOF
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
DB_ROOT_PASSWORD=root
USER_ID=1000
GROUP_ID=1000
EOF
        echo "Created .env with default values"
    fi
fi

echo ""
echo "Building Docker containers (this may take a few minutes)..."
docker-compose build --no-cache

echo ""
echo "Starting infrastructure services..."
docker-compose up -d traefik db redis

echo ""
echo "Waiting for database to be ready..."
sleep 10

echo ""
echo "Starting and initializing backend (Laravel)..."
docker-compose up -d backend
echo ""
echo "This will take 1-2 minutes. You can check progress with:"
echo "  docker-compose logs -f backend"
echo ""
echo "Waiting for backend initialization..."
sleep 60

echo ""
echo "Starting and initializing frontend (Nuxt)..."
docker-compose up -d frontend
echo ""
echo "This will take 1-2 minutes. You can check progress with:"
echo "  docker-compose logs -f frontend"
echo ""
echo "Waiting for frontend initialization..."
sleep 60

echo ""
echo "========================================"
echo "Project initialized successfully!"
echo "========================================"
echo ""
echo "Access points:"
echo "  - Frontend:           http://localhost:8080"
echo "  - Backend API:        http://api.localhost:8080"
echo "  - Traefik Dashboard:  http://localhost:8081"
echo ""
echo "Check initialization status:"
echo "  docker-compose ps"
echo ""
echo "View logs:"
echo "  docker-compose logs backend"
echo "  docker-compose logs frontend"
echo ""
echo "If services are not ready yet, wait a bit longer and check logs."
echo ""
