# Быстрое исправление

## Проблема: exec /usr/local/bin/docker-entrypoint.sh: no such file or directory

Файл не копируется в образ из-за проблем с `.dockerignore`.

## Решение:

### Шаг 1: Остановить контейнеры
```cmd
cd C:\Users\antyu\Desktop\architect\infra
docker-compose down
```

### Шаг 2: Удалить старые образы
```cmd
docker rmi architect-backend architect-frontend infra-backend infra-frontend 2>nul
```

### Шаг 3: Пересобрать образы
```cmd
docker-compose build --no-cache
```

### Шаг 4: Проверить что скрипт скопировался
```cmd
docker run --rm infra-backend ls -la /usr/local/bin/docker-entrypoint.sh
docker run --rm infra-frontend ls -la /usr/local/bin/docker-entrypoint.sh
```

Вы должны увидеть что-то вроде:
```
-rwxr-xr-x 1 root root 2847 Jan  1 12:00 /usr/local/bin/docker-entrypoint.sh
```

### Шаг 5: Запустить проект
```cmd
docker-compose up -d
```

### Шаг 6: Проверить логи
```cmd
docker-compose logs -f backend
```

В другом окне:
```cmd
cd C:\Users\antyu\Desktop\architect\infra
docker-compose logs -f frontend
```

## Если всё равно не работает:

### Проверьте что файлы существуют:
```cmd
cd C:\Users\antyu\Desktop\architect
dir backend\docker-entrypoint.sh
dir frontend\docker-entrypoint.sh
```

### Проверьте окончания строк (должны быть LF, не CRLF):
```cmd
cd backend
file docker-entrypoint.sh
```

Если показывает CRLF, исправьте:
```cmd
git config core.autocrlf input
git rm --cached docker-entrypoint.sh
git add docker-entrypoint.sh
git commit -m "fix: convert entrypoint to LF"
```

### Альтернативный метод - создать скрипт внутри Dockerfile:

Если ничего не помогает, можно создать скрипт прямо в Dockerfile.

**Для backend:** Отредактируйте `backend/Dockerfile` и добавьте перед ENTRYPOINT:

```dockerfile
RUN cat > /usr/local/bin/docker-entrypoint.sh <<'SCRIPT'
#!/bin/sh
echo "Starting backend..."
exec "$@"
SCRIPT

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
```

Затем пересоберите:
```cmd
cd infra
docker-compose build --no-cache backend
docker-compose up -d backend
```

## Быстрый тест:

Запустите `test-build.bat` из корня проекта - он покажет есть ли ошибки при сборке.
