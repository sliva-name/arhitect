@echo off
setlocal enabledelayedexpansion

echo Initializing project structure...
echo.

cd /d "%~dp0"

if not exist "infra\.env" (
    echo Creating environment configuration...
    copy "infra\.env.example" "infra\.env" >nul
    echo Created infra\.env
)

echo.
echo Building Docker containers (this may take a few minutes)...
cd infra
docker-compose build --no-cache

echo.
echo Starting infrastructure services...
docker-compose up -d traefik db redis

echo.
echo Waiting for database to be ready...
timeout /t 10 /nobreak >nul

echo.
echo Starting and initializing backend (Laravel)...
docker-compose up -d backend
echo.
echo This will take 1-2 minutes. You can check progress with:
echo   cd infra ^&^& docker-compose logs -f backend
echo.
echo Waiting for backend initialization...
timeout /t 60 /nobreak >nul

echo.
echo Starting and initializing frontend (Nuxt)...
docker-compose up -d frontend
echo.
echo This will take 1-2 minutes. You can check progress with:
echo   cd infra ^&^& docker-compose logs -f frontend
echo.
echo Waiting for frontend initialization...
timeout /t 60 /nobreak >nul

echo.
echo ========================================
echo Project initialized successfully!
echo ========================================
echo.
echo Access points:
echo   - Frontend:           http://localhost
echo   - Backend API:        http://api.localhost
echo   - Traefik Dashboard:  http://localhost:8080
echo.
echo Check initialization status:
echo   cd infra ^&^& docker-compose ps
echo.
echo View logs:
echo   cd infra ^&^& docker-compose logs backend
echo   cd infra ^&^& docker-compose logs frontend
echo.
echo If services are not ready yet, wait a bit longer and check logs.
echo.

pause
