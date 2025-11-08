#!/bin/bash
set -e

echo "🚀 Initializing project structure..."

cd "$(dirname "$0")"

if [ ! -f "infra/.env" ]; then
    echo "⚙️  Creating environment configuration..."
    cp infra/.env.example infra/.env
    echo "✅ Created infra/.env"
fi

echo ""
echo "📦 Building Docker containers..."
cd infra
docker-compose build

echo ""
echo "🔧 Starting services..."
docker-compose up -d traefik db redis

echo ""
echo "⏳ Waiting for database to be ready..."
sleep 10

echo ""
echo "🎨 Initializing backend (Laravel)..."
docker-compose up -d backend
echo "⏳ Waiting for Laravel initialization..."
sleep 15

echo ""
echo "🎨 Initializing frontend (Nuxt)..."
docker-compose up -d frontend
echo "⏳ Waiting for Nuxt initialization..."
sleep 15

echo ""
echo "✅ Project initialized successfully!"
echo ""
echo "📍 Access points:"
echo "  - Frontend:        http://localhost"
echo "  - Backend API:     http://api.localhost"
echo "  - Traefik Dashboard: http://localhost:8080"
echo ""
echo "🔍 Check logs with:"
echo "  cd infra && docker-compose logs -f backend"
echo "  cd infra && docker-compose logs -f frontend"
echo ""
echo "🛠️  Useful commands:"
echo "  cd infra && docker-compose exec backend php artisan migrate"
echo "  cd infra && docker-compose exec backend composer require <package>"
echo "  cd infra && docker-compose exec frontend npm install <package>"
