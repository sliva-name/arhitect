# Project Initialization Scripts

## Quick Start

### Windows:
```cmd
init.bat
```

### Linux/Mac:
```bash
chmod +x init.sh
./init.sh
```

## What happens during initialization?

1. **Environment Setup**: Creates `.env` file in `infra/` directory
2. **Docker Build**: Builds all necessary containers
3. **Services Start**: Starts Traefik, PostgreSQL, and Redis
4. **Backend Init**: Initializes a fresh Laravel project (if not exists)
5. **Frontend Init**: Initializes a fresh Nuxt project (if not exists)

## Manual Initialization

### Backend (Laravel)

```bash
cd infra
docker-compose up -d backend
docker-compose exec backend composer create-project laravel/laravel .
docker-compose exec backend php artisan key:generate
docker-compose exec backend composer require --dev laravel/pint phpstan/phpstan nunomaduro/larastan
```

### Frontend (Nuxt)

```bash
cd infra
docker-compose up -d frontend
docker-compose exec frontend npx nuxi@latest init .
docker-compose exec frontend npm install
```

## Access Points

- **Frontend**: http://localhost
- **Backend API**: http://api.localhost
- **Traefik Dashboard**: http://localhost:8080
- **PostgreSQL**: localhost:5432 (user: laravel, password: secret, database: laravel)
- **Redis**: localhost:6379

## Useful Commands

### Backend (Laravel)
```bash
cd infra

# Run migrations
docker-compose exec backend php artisan migrate

# Install package
docker-compose exec backend composer require vendor/package

# Run Pint (code style)
docker-compose exec backend ./vendor/bin/pint

# Run PHPStan (static analysis)
docker-compose exec backend ./vendor/bin/phpstan analyse

# Run tests
docker-compose exec backend php artisan test

# Enter container shell
docker-compose exec backend sh
```

### Frontend (Nuxt)
```bash
cd infra

# Install package
docker-compose exec frontend npm install package-name

# Run build
docker-compose exec frontend npm run build

# Enter container shell
docker-compose exec frontend sh
```

### General
```bash
cd infra

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Restart service
docker-compose restart backend
docker-compose restart frontend

# Stop all services
docker-compose down

# Remove all data (including volumes)
docker-compose down -v
```
