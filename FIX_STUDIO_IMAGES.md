# Исправление проблемы с образами Supabase Studio

## Проблема

Studio не отображает данные, возможно из-за несовместимости образов или проблем с pg-meta.

## Решения

### Вариант 1: Использовать упрощенную конфигурацию БЕЗ pg-meta (рекомендуется)

Используйте `docker-compose.prod-simple.yml` - Studio без pg-meta, подключение через веб-интерфейс:

```bash
cd /opt/mediavelichia

# Остановите текущие контейнеры
docker compose -f docker-compose.prod.yml down

# Используйте упрощенную конфигурацию
docker compose -f docker-compose.prod-simple.yml up -d

# Проверьте логи
docker logs mediavelichie-supabase-studio --tail 50
```

После запуска откройте Studio и подключитесь вручную:
- Host: `194.58.88.127` (или `supabase` если Studio поддерживает)
- Port: `5432`
- Database: `postgres`
- User: `postgres`
- Password: из `.env`

### Вариант 2: Использовать старую проверенную версию Studio

В `docker-compose.prod.yml` замените:
```yaml
image: supabase/studio:latest
```

На:
```yaml
image: supabase/studio:20231220-0a8c4b5
```

Затем перезапустите:
```bash
docker compose -f docker-compose.prod.yml pull supabase-studio
docker compose -f docker-compose.prod.yml up -d supabase-studio
```

### Вариант 3: Переключиться на pgAdmin (самый надежный)

pgAdmin работает стабильно с обычным PostgreSQL и не требует дополнительных сервисов:

```bash
cd /opt/mediavelichia

# Используйте скрипт для добавления pgAdmin
chmod +x switch-to-pgadmin.sh
./switch-to-pgadmin.sh
```

Или вручную добавьте в `docker-compose.prod.yml`:

```yaml
pgadmin:
  image: dpage/pgadmin4:latest
  container_name: mediavelichie-pgadmin
  ports:
    - "5050:80"
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@example.com
    PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin123}
  depends_on:
    supabase:
      condition: service_healthy
  networks:
    - mediavelichie-network
```

Доступ: http://194.58.88.127:5050

### Вариант 4: Проверить и обновить образы

```bash
# Проверьте какие образы используются
docker images | grep supabase

# Обновите образы
docker compose -f docker-compose.prod.yml pull

# Пересоздайте контейнеры
docker compose -f docker-compose.prod.yml up -d --force-recreate supabase-studio supabase-meta
```

## Рекомендация

**Используйте pgAdmin** - это самый надежный вариант для работы с PostgreSQL без полного Supabase стека. Studio требует много дополнительных сервисов и может быть нестабильным в standalone режиме.

pgAdmin предоставляет:
- ✅ Стабильную работу с PostgreSQL
- ✅ Полный функционал управления БД
- ✅ Не требует дополнительных сервисов
- ✅ Простое подключение
- ✅ Хорошую документацию

## Проверка после исправления

1. Откройте веб-интерфейс (Studio или pgAdmin)
2. Подключитесь к БД используя данные из `.env`
3. Проверьте что видите таблицы и можете выполнять запросы
