# Troubleshooting Guide

## Common Issues and Solutions

### Issue: Entrypoint script errors

**Symptoms:**
- Container fails to start
- Errors like "exec format error" or "no such file or directory"

**Solutions:**

1. **Line ending issues (CRLF vs LF):**
   ```bash
   # Convert to Unix line endings
   cd backend
   dos2unix docker-entrypoint.sh
   # Or on Windows with Git:
   git config core.autocrlf input
   git rm --cached docker-entrypoint.sh
   git add docker-entrypoint.sh
   ```

2. **Rebuild containers:**
   ```bash
   cd infra
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### Issue: Project not initialized

**Symptoms:**
- "artisan not found" or "nuxt.config not found"
- Container restarts constantly

**Check logs:**
```bash
cd infra
docker-compose logs backend
docker-compose logs frontend
```

**Solutions:**

1. **Wait longer** - Initial setup takes 2-3 minutes per service
2. **Check for conflicts** - Remove any existing non-Laravel/Nuxt files in backend/frontend folders

### Issue: Non-Laravel/Nuxt project detected

**Symptoms:**
- "Found non-Laravel project, cleaning up..."
- Unexpected reinitialization

**Cause:** 
Existing `composer.json` or `package.json` without Laravel/Nuxt files.

**Solution:**
The entrypoint script will automatically clean and reinitialize. To prevent this, ensure:
- Backend has: `artisan` + `bootstrap/app.php`
- Frontend has: `nuxt.config.ts` or `nuxt.config.js`

### Full reset and reinitialization

```bash
cd infra

# Stop all services
docker-compose down -v

# Remove generated project files
cd ..

# Windows:
if exist backend\vendor rmdir /s /q backend\vendor 2>nul
if exist backend\node_modules rmdir /s /q backend\node_modules 2>nul
if exist frontend\node_modules rmdir /s /q frontend\node_modules 2>nul
for %%F in (backend\*) do if not "%%~nxF"==".dockerignore" if not "%%~nxF"=="Dockerfile" if not "%%~nxF"=="docker-entrypoint.sh" if not "%%~nxF"==".gitkeep" del /q "%%F" 2>nul
for %%F in (frontend\*) do if not "%%~nxF"==".dockerignore" if not "%%~nxF"=="Dockerfile" if not "%%~nxF"=="docker-entrypoint.sh" if not "%%~nxF"==".gitkeep" del /q "%%F" 2>nul

# Linux/Mac:
rm -rf backend/* frontend/*

# Keep only infrastructure files (they are protected by .gitkeep)

cd infra

# Rebuild and restart
docker-compose build --no-cache
docker-compose up -d

# Monitor initialization
docker-compose logs -f
```

## Manual Project Initialization

If automatic initialization fails, you can initialize manually:

### Backend (Laravel):

```bash
cd infra
docker-compose exec backend sh

# Inside container:
composer create-project laravel/laravel /tmp/laravel --no-interaction --prefer-dist
cp -a /tmp/laravel/. /var/www/html/
rm -rf /tmp/laravel
php artisan key:generate
composer require --dev laravel/pint phpstan/phpstan nunomaduro/larastan
exit

# Restart container
docker-compose restart backend
```

### Frontend (Nuxt):

```bash
cd infra
docker-compose exec frontend sh

# Inside container:
npx nuxi@latest init /tmp/nuxt --no-install --force
cp -a /tmp/nuxt/. /app/
rm -rf /tmp/nuxt
npm install
exit

# Restart container
docker-compose restart frontend
```

## Environment Issues

### Missing .env file

The entrypoint script creates a minimal `.env` if `.env.example` is missing:

**Backend:**
```env
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### Database connection issues

1. **Check MySQL is ready:**
   ```bash
   docker-compose logs db
   ```

2. **Verify credentials in infra/.env:**
   ```env
   DB_DATABASE=laravel
   DB_USERNAME=laravel
   DB_PASSWORD=secret
   DB_ROOT_PASSWORD=root
   ```

3. **Test connection:**
   ```bash
   docker-compose exec backend php artisan migrate
   ```

## Port Conflicts

If ports 80, 443, 3306, or 6379 are in use:

1. Edit `infra/docker-compose.yml`
2. Change port mappings:
   ```yaml
   ports:
     - "8080:80"  # Change external port
   ```

## Performance Issues

### Slow initialization on Windows

Use WSL2 for better performance:

1. Install WSL2
2. Move project to WSL filesystem
3. Run Docker Desktop with WSL2 backend

### Dependencies installation is slow

The first installation downloads all packages. Subsequent starts use cached volumes.

## Checking Container Status

```bash
cd infra

# List all containers
docker-compose ps

# Check specific service health
docker-compose exec backend php artisan --version
docker-compose exec frontend npm --version
```

## Clean rebuild

For persistent issues:

```bash
cd infra

# Nuclear option: remove everything
docker-compose down -v
docker system prune -a --volumes -f

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```

## Getting Help

When reporting issues, include:

1. **Container logs:**
   ```bash
   docker-compose logs backend > backend.log
   docker-compose logs frontend > frontend.log
   ```

2. **Container status:**
   ```bash
   docker-compose ps
   ```

3. **System info:**
   ```bash
   docker --version
   docker-compose --version
   ```
