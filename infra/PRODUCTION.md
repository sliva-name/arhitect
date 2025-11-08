# Production Deployment Guide

## Быстрый старт для продакшена

### Шаг 1: Настройка переменных окружения

В файле `infra/.env` измените **только 2 строки**:

```env
ENVIRONMENT=production
PROD_DOMAIN=yourdomain.com
PROD_EMAIL=your-email@example.com
```

### Шаг 2: Запуск продакшена

```bash
cd infra
./start-prod.sh
```

Всё! Приложение запустится в production режиме с:
- ✅ HTTPS (Let's Encrypt)
- ✅ Оптимизированными Docker образами
- ✅ PHP-FPM + Nginx
- ✅ Кэшированием Laravel
- ✅ Закрытыми портами БД/Redis
- ✅ Автоматическими бэкапами базы данных

## Что изменилось автоматически:

1. **Traefik**: Настроен для HTTPS с Let's Encrypt
2. **Backend**: Использует PHP-FPM вместо `php artisan serve`
3. **Frontend**: Production build Nuxt (SSR)
4. **Безопасность**: Порты БД и Redis закрыты
5. **Оптимизация**: Laravel кэши, Opcache, оптимизированный autoloader
6. **Бэкапы**: Автоматические ежедневные бэкапы PostgreSQL (по умолчанию в 2:00 AM)

## Разработка (по умолчанию)

Для локальной разработки ничего менять не нужно:

```bash
cd infra
./init.sh  # или init.bat на Windows
```

Или просто:

```bash
cd infra
docker-compose up -d
```

## Переключение между режимами

- **Development**: `ENVIRONMENT=development` (по умолчанию)
- **Production**: `ENVIRONMENT=production` + запуск `./start-prod.sh`

## Важно для продакшена:

1. Убедитесь, что домен указывает на ваш сервер
2. Откройте порты 80 и 443 в firewall
3. Настройте `.env` файл с production значениями
4. Первый запуск может занять время для получения SSL сертификата

## Бэкапы базы данных

Автоматические бэкапы PostgreSQL настроены по умолчанию:
- **Расписание**: Ежедневно в 2:00 AM (настраивается через `BACKUP_SCHEDULE`)
- **Хранение**: 7 дней (настраивается через `BACKUP_RETENTION_DAYS`)
- **Расположение**: `infra/backups/`
- **Формат**: Сжатые SQL дампы (`.sql.gz`)

### Настройка бэкапов

В `infra/.env` добавьте:
```env
BACKUP_SCHEDULE=0 2 * * *      # Cron формат (по умолчанию: ежедневно в 2 AM)
BACKUP_RETENTION_DAYS=7        # Хранить бэкапы N дней (по умолчанию: 7)
```

### Ручной бэкап

```bash
cd infra
docker-compose -f docker-compose.yml -f docker-compose.prod.yml exec db-backup /backup-script.sh
```

### Восстановление из бэкапа

```bash
cd infra
gunzip < backups/backup_laravel_YYYYMMDD_HHMMSS.sql.gz | docker-compose -f docker-compose.yml -f docker-compose.prod.yml exec -T db psql -U laravel -d laravel
```

## Структура файлов:

```
infra/
├── docker-compose.yml          # Основной файл (dev по умолчанию)
├── docker-compose.prod.yml     # Production override
├── start-prod.sh               # Скрипт запуска прода
├── backup-script.sh            # Скрипт бэкапов БД
├── backups/                    # Директория с бэкапами (создается автоматически)
└── .env                        # Конфигурация (ENVIRONMENT=production)

backend/
├── Dockerfile                  # Development
├── Dockerfile.prod             # Production
└── docker-entrypoint-prod.sh  # Production entrypoint

frontend/
├── Dockerfile                  # Development
└── Dockerfile.prod             # Production
```

