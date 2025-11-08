# Инструкция по устранению проблемы

## Что было исправлено:

1. **Синтаксис entrypoint скриптов** - убран `set -e`, который не поддерживается в `/bin/sh`
2. **Права доступа** - скрипты теперь копируются в Dockerfile и получают права на выполнение
3. **Docker Compose** - убраны дублирующие entrypoint и command директивы

## Как перезапустить проект:

### Шаг 1: Остановить и удалить контейнеры
```bash
cd infra
docker-compose down
```

### Шаг 2: Пересобрать образы
```bash
docker-compose build --no-cache
```

### Шаг 3: Запустить проект заново
```bash
docker-compose up -d
```

### Шаг 4: Проверить логи инициализации

**Backend:**
```bash
docker-compose logs -f backend
```
Вы должны увидеть: "Initializing new Laravel project..." и затем "Laravel project initialized successfully!"

**Frontend:**
```bash
docker-compose logs -f frontend
```
Вы должны увидеть: "Initializing new Nuxt project..." и затем "Nuxt project initialized successfully!"

### Шаг 5: Проверить доступность

- Frontend: http://localhost
- Backend API: http://api.localhost
- Traefik Dashboard: http://localhost:8080

## Если всё ещё есть проблемы:

### Полная очистка и переинициализация:
```bash
cd infra

# Остановить и удалить всё
docker-compose down -v

# Удалить созданные файлы проектов (если есть)
# Windows:
cd ..
rmdir /s /q backend\vendor backend\node_modules frontend\node_modules 2>nul

# Вернуться в infra
cd infra

# Пересобрать без кэша
docker-compose build --no-cache

# Запустить
docker-compose up -d

# Следить за логами
docker-compose logs -f
```

## Проверка статуса контейнеров:
```bash
cd infra
docker-compose ps
```

Все контейнеры должны быть в статусе "Up".

## Ручная инициализация (если автоматическая не сработала):

### Backend:
```bash
cd infra
docker-compose exec backend composer create-project laravel/laravel /tmp/laravel
docker-compose exec backend sh -c "cp -r /tmp/laravel/* /var/www/html/ && rm -rf /tmp/laravel"
docker-compose exec backend php artisan key:generate
docker-compose restart backend
```

### Frontend:
```bash
cd infra
docker-compose exec frontend npx nuxi@latest init /tmp/nuxt --no-install --force
docker-compose exec frontend sh -c "cp -r /tmp/nuxt/* /app/ && rm -rf /tmp/nuxt"
docker-compose exec frontend npm install
docker-compose restart frontend
```
