@echo off
setlocal enabledelayedexpansion

echo 🚀 Initializing project structure...
echo.

cd /d "%~dp0"

if not exist "infra\.env" (
    echo ⚙️  Creating environment configuration...
    copy "infra\.env.example" "infra\.env" >nul
    echo ✅ Created infra\.env
)

echo.
echo 📦 Building Docker containers...
cd infra
docker-compose build

echo.
echo 🔧 Starting services...
docker-compose up -d traefik db redis

echo.
echo ⏳ Waiting for database to be ready...
timeout /t 10 /nobreak >nul

echo.
echo 🎨 Initializing backend (Laravel)...
docker-compose up -d backend
echo ⏳ Waiting for Laravel initialization...
timeout /t 15 /nobreak >nul

echo.
echo 🎨 Initializing frontend (Nuxt)...
docker-compose up -d frontend
echo ⏳ Waiting for Nuxt initialization...
timeout /t 15 /nobreak >nul

echo.
echo ✅ Project initialized successfully!
echo.
echo 📍 Access points:
echo   - Frontend:        http://localhost
echo   - Backend API:     http://api.localhost
echo   - Traefik Dashboard: http://localhost:8080
echo.
echo 🔍 Check logs with:
echo   cd infra ^&^& docker-compose logs -f backend
echo   cd infra ^&^& docker-compose logs -f frontend
echo.
echo 🛠️  Useful commands:
echo   cd infra ^&^& docker-compose exec backend php artisan migrate
echo   cd infra ^&^& docker-compose exec backend composer require ^<package^>
echo   cd infra ^&^& docker-compose exec frontend npm install ^<package^>
echo.

pause
