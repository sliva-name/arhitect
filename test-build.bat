@echo off
echo Testing Docker build...
echo.

cd /d "%~dp0"

echo Building backend image...
cd backend
docker build -t test-backend . 2>&1 | findstr /C:"COPY" /C:"Error" /C:"error"
if %errorlevel% equ 0 (
    echo Backend build: Check output above
) else (
    echo Backend build: OK
)
echo.

cd ..

echo Building frontend image...
cd frontend
docker build -t test-frontend . 2>&1 | findstr /C:"COPY" /C:"Error" /C:"error"
if %errorlevel% equ 0 (
    echo Frontend build: Check output above
) else (
    echo Frontend build: OK
)
echo.

cd ..

echo.
echo Test complete. If no errors above, rebuild with:
echo   cd infra
echo   docker-compose build --no-cache
echo   docker-compose up -d
echo.

pause
