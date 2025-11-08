@echo off
setlocal enabledelayedexpansion

echo Initializing project structure...
echo.

cd /d "%~dp0"

if not exist ".env" (
    if exist ".env.example" (
        echo Creating environment configuration from .env.example...
        copy ".env.example" ".env" >nul
        echo Created .env
        echo Please edit .env if you need to change default values.
    ) else (
        echo WARNING: .env.example not found!
        echo Creating minimal .env...
        (
            echo DB_DATABASE=laravel
            echo DB_USERNAME=laravel
            echo DB_PASSWORD=secret
            echo DB_ROOT_PASSWORD=root
            echo USER_ID=1000
            echo GROUP_ID=1000
        ) > ".env"
        echo Created .env with default values
    )
)

echo.
echo Building Docker containers (this may take a few minutes)...
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
echo   docker-compose logs -f backend
echo.
echo Waiting for backend initialization...
timeout /t 60 /nobreak >nul

echo.
echo Starting and initializing frontend (Nuxt)...
docker-compose up -d frontend
echo.
echo This will take 1-2 minutes. You can check progress with:
echo   docker-compose logs -f frontend
echo.
echo Waiting for frontend initialization...
timeout /t 60 /nobreak >nul

echo.
echo ========================================
echo Project initialized successfully!
echo ========================================
echo.
echo Access points:
echo   - Frontend:           http://localhost:8080
echo   - Backend API:        http://api.localhost:8080
echo   - Traefik Dashboard:  http://localhost:8081
echo.
echo Check initialization status:
echo   docker-compose ps
echo.
echo View logs:
echo   docker-compose logs backend
echo   docker-compose logs frontend
echo.
echo If services are not ready yet, wait a bit longer and check logs.
echo.

pause
