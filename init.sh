#!/bin/bash

echo "Initializing project structure..."

cd "$(dirname "$0")"

if [ ! -f "infra/.env" ]; then
    echo "Creating environment configuration..."
    cp infra/.env.example infra/.env
    echo "Created infra/.env"
fi

echo ""
echo "Building Docker containers (this may take a few minutes)..."
cd infra
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
echo "  cd infra && docker-compose logs -f backend"
echo ""
echo "Waiting for backend initialization..."
sleep 60

echo ""
echo "Starting and initializing frontend (Nuxt)..."
docker-compose up -d frontend
echo ""
echo "This will take 1-2 minutes. You can check progress with:"
echo "  cd infra && docker-compose logs -f frontend"
echo ""
echo "Waiting for frontend initialization..."
sleep 60

echo ""
echo "========================================"
echo "Project initialized successfully!"
echo "========================================"
echo ""
echo "Access points:"
echo "  - Frontend:           http://localhost"
echo "  - Backend API:        http://api.localhost"
echo "  - Traefik Dashboard:  http://localhost:8080"
echo ""
echo "Check initialization status:"
echo "  cd infra && docker-compose ps"
echo ""
echo "View logs:"
echo "  cd infra && docker-compose logs backend"
echo "  cd infra && docker-compose logs frontend"
echo ""
echo "If services are not ready yet, wait a bit longer and check logs."
echo ""
