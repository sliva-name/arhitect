# Architect - Laravel + Nuxt 4 Full-Stack Template

Готовый шаблон для быстрого старта full-stack приложений на Laravel (Backend API) и Nuxt 4 (Frontend).

## 🚀 Быстрый старт

### Требования

- Docker и Docker Compose
- Git

### Установка

1. **Клонируйте репозиторий:**
   ```bash
   git clone <repository-url>
   cd architect
   ```

2. **Запустите инициализацию:**

   **Linux/Mac:**
   ```bash
   cd infra
   chmod +x init.sh
   ./init.sh
   ```

   **Windows:**
   ```cmd
   cd infra
   init.bat
   ```

3. **Дождитесь завершения инициализации** (1-3 минуты)

4. **Откройте в браузере:**
   - Frontend: http://localhost:8080
   - Backend API: http://api.localhost:8080
   - Traefik Dashboard: http://localhost:8081

## 📁 Структура проекта

```
architect/
├── infra/                    # Docker Compose конфигурация
│   ├── docker-compose.yml    # Оркестрация всех сервисов
│   ├── .env.example          # Пример конфигурации
│   ├── init.sh               # Скрипт инициализации (Linux/Mac)
│   ├── init.bat              # Скрипт инициализации (Windows)
│   └── fix-permissions.sh    # Скрипт исправления прав доступа
│
├── backend/                  # Laravel Backend (авто-инициализация)
│   ├── Dockerfile            # Образ для Laravel
│   ├── docker-entrypoint.sh # Скрипт инициализации Laravel
│   ├── .dockerignore        # Исключения для Docker
│   └── .gitlab-ci.yml       # CI/CD для Backend
│
├── frontend/                 # Nuxt 4 Frontend (авто-инициализация)
│   ├── Dockerfile            # Образ для Nuxt
│   ├── docker-entrypoint.sh # Скрипт инициализации Nuxt
│   ├── .dockerignore        # Исключения для Docker
│   └── .gitlab-ci.yml       # CI/CD для Frontend
│
└── docs/                     # Документация
    ├── README.md            # Основная документация
    ├── QUICK_START.md       # Быстрый старт
    ├── FILES.md             # Структура файлов
    ├── AGENTS.md            # Документация для AI
    └── TROUBLESHOOTING.md   # Решение проблем
```

## 🔧 Конфигурация

### Настройка переменных окружения

1. Перейдите в директорию `infra`:
   ```bash
   cd infra
   ```

2. Скопируйте пример конфигурации:
   ```bash
   cp .env.example .env
   ```

3. Отредактируйте `infra/.env` при необходимости:
   ```env
   # Database Configuration
   DB_DATABASE=laravel
   DB_USERNAME=laravel
   DB_PASSWORD=secret
   DB_ROOT_PASSWORD=root

   # User ID and Group ID (для правильных прав доступа к файлам)
   USER_ID=1000
   GROUP_ID=1000
   ```

### Порты

По умолчанию используются следующие порты:

- **8080** - HTTP (Frontend и Backend через Traefik)
- **8443** - HTTPS
- **8081** - Traefik Dashboard
- **5432** - PostgreSQL
- **6379** - Redis

Если порты заняты, измените их в `infra/docker-compose.yml`.

## 🛠️ Разработка

### Backend (Laravel)

```bash
cd infra

# Выполнить миграции
docker-compose exec backend php artisan migrate

# Создать контроллер
docker-compose exec backend php artisan make:controller Api/ExampleController

# Создать модель с миграцией
docker-compose exec backend php artisan make:model Example -m

# Установить пакет
docker-compose exec backend composer require vendor/package

# Проверка кода (Pint)
docker-compose exec backend ./vendor/bin/pint

# Статический анализ (PHPStan)
docker-compose exec backend ./vendor/bin/phpstan analyse --memory-limit=512M

# Запустить тесты
docker-compose exec backend php artisan test

# Войти в контейнер
docker-compose exec backend sh
```

### Frontend (Nuxt 4)

```bash
cd infra

# Установить пакет
docker-compose exec frontend npm install package-name

# Создать страницу
docker-compose exec frontend npx nuxi add page about

# Создать компонент
docker-compose exec frontend npx nuxi add component MyComponent

# Собрать для продакшена
docker-compose exec frontend npm run build

# Войти в контейнер
docker-compose exec frontend sh
```

## 📝 Полезные команды

### Управление контейнерами

```bash
cd infra

# Запустить все сервисы
docker-compose up -d

# Остановить все сервисы
docker-compose down

# Перезапустить сервис
docker-compose restart backend
docker-compose restart frontend

# Просмотр логов
docker-compose logs -f backend
docker-compose logs -f frontend

# Статус контейнеров
docker-compose ps
```

### Исправление прав доступа

Если файлы создаются с неправильными правами доступа:

```bash
cd infra
./fix-permissions.sh
```

Или вручную:

```bash
cd infra
docker-compose exec -T frontend chown -R $(id -u):$(id -g) /app
docker-compose exec -T backend chown -R $(id -u):$(id -g) /var/www/html
```

## 🔍 Troubleshooting

Смотрите [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) для решения проблем.

## 📚 Дополнительная документация

- [Быстрый старт](docs/QUICK_START.md)
- [Структура файлов](docs/FILES.md)
- [Решение проблем](docs/TROUBLESHOOTING.md)
- [Документация для AI](docs/AGENTS.md)

## 🎯 Особенности

- ✅ Автоматическая инициализация Laravel и Nuxt проектов последних версий
- ✅ Правильные права доступа к файлам (не root)
- ✅ TypeScript поддержка в Nuxt
- ✅ Автоматическая установка PHPStan и Pint для качества кода
- ✅ Tests для качества кода
- ✅ Hot reload для разработки
- ✅ Все зависимости видны на хосте (node_modules, vendor)
- ✅ Отдельные CI/CD конфигурации для backend и frontend
- ✅ Выгрузка на боевой сервер с заменой всего 1 строки кода

## 📄 Лицензия

MIT
