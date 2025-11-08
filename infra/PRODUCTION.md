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

## Что изменилось автоматически:

1. **Traefik**: Настроен для HTTPS с Let's Encrypt
2. **Backend**: Использует PHP-FPM вместо `php artisan serve`
3. **Frontend**: Production build Nuxt (SSR)
4. **Безопасность**: Порты БД и Redis закрыты
5. **Оптимизация**: Laravel кэши, Opcache, оптимизированный autoloader

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

## Структура файлов:

```
infra/
├── docker-compose.yml          # Основной файл (dev по умолчанию)
├── docker-compose.prod.yml     # Production override
├── start-prod.sh               # Скрипт запуска прода
└── .env                        # Конфигурация (ENVIRONMENT=production)

backend/
├── Dockerfile                  # Development
├── Dockerfile.prod             # Production
└── docker-entrypoint-prod.sh  # Production entrypoint

frontend/
├── Dockerfile                  # Development
└── Dockerfile.prod             # Production
```

