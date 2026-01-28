# Исправление ошибки Studio: "expected string, received undefined"

## Проблема

После добавления pg-meta сервиса Studio показывает ошибку:
```
Error: [ { "expected": "string", "code": "invalid_type", "path": [ "formattedError" ], "message": "Invalid input: expected string, received undefined" } ]
```

## Причины

1. **pg-meta не может подключиться к БД** - неправильный пользователь или пароль
2. **pg-meta возвращает неверный формат данных** - проблема с конфигурацией
3. **Studio не может получить данные от pg-meta** - проблема с сетью или URL

## Решение

### Шаг 1: Проверьте логи pg-meta

```bash
docker logs mediavelichie-supabase-meta --tail 50
```

Ищите ошибки подключения к БД или ошибки парсинга.

### Шаг 2: Проверьте пользователя БД

```bash
# Проверьте какие пользователи есть в БД
docker exec mediavelichie-supabase-db psql -U postgres -c "\du"

# Если supabase_admin не существует, используйте postgres
```

### Шаг 3: Исправьте конфигурацию

Убедитесь что в `docker-compose.prod.yml` используется правильный пользователь:

```yaml
supabase-meta:
  environment:
    PG_META_DB_USER: postgres  # Используйте postgres, не supabase_admin
    PG_META_DB_PASSWORD: ${POSTGRES_PASSWORD}
```

### Шаг 4: Перезапустите сервисы

```bash
cd /opt/mediavelichia

# Перезапустите pg-meta
docker compose -f docker-compose.prod.yml restart supabase-meta

# Подождите 10 секунд
sleep 10

# Перезапустите Studio
docker compose -f docker-compose.prod.yml restart supabase-studio
```

### Шаг 5: Проверьте подключение pg-meta к БД

```bash
# Проверьте health endpoint
docker exec mediavelichie-supabase-meta wget -qO- http://localhost:8080/health

# Или извне контейнера
curl http://localhost:8080/health
```

## Альтернативное решение: Отключить pg-meta

Если pg-meta не работает, можно вернуться к ручному подключению:

```yaml
supabase-studio:
  environment:
    # Уберите STUDIO_PG_META_URL
    # STUDIO_PG_META_URL: http://supabase-meta:8080
    
    # Используйте прямые переменные (Studio попросит подключиться вручную)
    POSTGRES_HOST: supabase
    POSTGRES_PORT: 5432
    POSTGRES_DB: postgres
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

Затем подключитесь через веб-интерфейс Studio вручную.

## Быстрое исправление

Используйте скрипт:

```bash
cd /opt/mediavelichia
chmod +x fix-pg-meta-user.sh
./fix-pg-meta-user.sh
```

## Проверка после исправления

1. Откройте Studio: http://194.58.88.127:3000
2. Очистите кеш браузера (Ctrl+Shift+R)
3. Если ошибка сохраняется, проверьте логи:
   ```bash
   docker logs mediavelichie-supabase-meta --tail 100
   docker logs mediavelichie-supabase-studio --tail 100
   ```
