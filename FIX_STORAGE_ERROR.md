# Исправление ошибки "Failed to retrieve buckets" в Studio

## Проблема

Studio показывает ошибку:
```
Failed to retrieve buckets
Error: API error happened while trying to communicate with the server.
```

## Причина

Studio пытается получить доступ к Storage API (buckets), но у нас нет полного Supabase стека - только PostgreSQL и pg-meta. Studio ожидает наличие:
- Storage API
- PostgREST API
- Kong Gateway
- Auth API

## Решение

### Вариант 1: Игнорировать ошибку (рекомендуется)

Эта ошибка появляется только при попытке открыть раздел **Storage** в Studio. Основные функции БД работают нормально:

- ✅ **Table Editor** - просмотр и редактирование таблиц
- ✅ **SQL Editor** - выполнение SQL запросов
- ✅ **Database** - управление схемой БД
- ❌ **Storage** - не работает (ожидается)

**Просто не используйте раздел Storage** - он не нужен для работы с базой данных.

### Вариант 2: Обновить конфигурацию (уже применено)

Добавлены переменные окружения для отключения Storage функций:

```yaml
DISABLE_STORAGE: "true"
SUPABASE_URL: http://localhost:8000  # Фиктивный URL
```

### Вариант 3: Добавить минимальный Supabase стек

Если нужен Storage, можно добавить минимальные сервисы:

```yaml
# PostgREST API
postgrest:
  image: postgrest/postgrest:v12.2.12
  environment:
    PGRST_DB_URI: postgres://postgres:${POSTGRES_PASSWORD}@supabase:5432/postgres
    PGRST_DB_SCHEMAS: public
    PGRST_JWT_SECRET: ${JWT_SECRET}

# Storage API
storage:
  image: supabase/storage-api:v1.25.7
  environment:
    DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD}@supabase:5432/postgres
    POSTGREST_URL: http://postgrest:3000
```

Но это значительно усложнит конфигурацию и увеличит потребление ресурсов.

## Применение исправления

```bash
cd /opt/mediavelichia

# Обновите код
git pull origin main

# Перезапустите Studio
docker compose -f docker-compose.prod.yml restart supabase-studio

# Проверьте логи
docker logs mediavelichie-supabase-studio --tail 50
```

## Проверка работы

1. Откройте Studio: http://194.58.88.127:3000
2. Используйте разделы:
   - **Table Editor** - должен работать ✅
   - **SQL Editor** - должен работать ✅
   - **Database** - должен работать ✅
3. Избегайте раздела **Storage** - там будет ошибка ❌

## Альтернатива: Использовать pgAdmin

Если Studio вызывает проблемы, используйте pgAdmin для управления БД:

```yaml
pgadmin:
  image: dpage/pgadmin4:latest
  ports:
    - "5050:80"
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@example.com
    PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-change-me}
```

pgAdmin работает только с PostgreSQL и не требует дополнительных сервисов.
