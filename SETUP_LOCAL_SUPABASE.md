# Установка и настройка локального Supabase

## Описание

Скрипт `setup-local-supabase.sh` автоматически устанавливает и настраивает локальный контейнер Supabase (PostgreSQL) для проекта Mediavelichia.

## Что делает скрипт

1. ✅ Проверяет и создает файл `.env` если его нет
2. ✅ Генерирует безопасные секреты (`POSTGRES_PASSWORD`, `JWT_SECRET`) если их нет
3. ✅ Генерирует JWT токены для подключения (`SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`)
4. ✅ Обновляет файл `.env` с правильными значениями
5. ✅ Запускает контейнер Supabase из `docker-compose.prod.yml`
6. ✅ Ожидает готовности базы данных
7. ✅ Выводит все данные для подключения

## Использование

### На сервере выполните:

```bash
cd /opt/mediavelichia

# Обновляем код из репозитория
git pull origin main

# Делаем скрипт исполняемым
chmod +x setup-local-supabase.sh

# Запускаем установку
./setup-local-supabase.sh
```

## Что будет создано/настроено

### Контейнер Docker
- **Имя контейнера**: `mediavelichie-supabase-db`
- **Образ**: `supabase/postgres:15.1.0.117`
- **Порт**: `5432` (PostgreSQL)
- **Volume**: `supabase-db-data` (для хранения данных)

### Переменные окружения в `.env`

После выполнения скрипта в файле `.env` будут настроены:

```bash
# Пароль для PostgreSQL
POSTGRES_PASSWORD=<сгенерированный-секрет>

# JWT секрет для подписи токенов
JWT_SECRET=<сгенерированный-секрет>

# URL для подключения к Supabase
SUPABASE_URL=http://<IP-сервера>:5432

# Anon ключ (для frontend)
SUPABASE_ANON_KEY=<JWT-токен-с-ролью-anon>

# Service Role ключ (для backend)
SUPABASE_SERVICE_KEY=<JWT-токен-с-ролью-service_role>

# Storage bucket
SUPABASE_BUCKET=portfolio
```

## Данные для подключения

После успешной установки скрипт выведет:

- **SUPABASE_URL** - URL для подключения к Supabase
- **SUPABASE_ANON_KEY** - Ключ для анонимного доступа (frontend)
- **SUPABASE_SERVICE_KEY** - Ключ для полного доступа (backend)
- **Подключение к БД** - Host, Port, Database, User, Password

## Проверка работы

### Проверка статуса контейнера

```bash
docker ps | grep supabase
```

### Проверка подключения к базе данных

```bash
docker exec mediavelichie-supabase-db pg_isready -U postgres
```

### Просмотр логов

```bash
docker logs mediavelichie-supabase-db
```

### Подключение к базе данных

```bash
docker exec -it mediavelichie-supabase-db psql -U postgres
```

## Управление контейнером

### Остановка

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml stop supabase
```

### Запуск

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml start supabase
```

### Перезапуск

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml restart supabase
```

### Удаление (с сохранением данных)

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml stop supabase
docker compose -f docker-compose.prod.yml rm supabase
```

### Полное удаление (включая данные)

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml down -v supabase-db-data
```

## Применение миграций

После установки Supabase, примените миграции базы данных:

```bash
cd /opt/mediavelichia

# Подключение к контейнеру
docker exec -i mediavelichie-supabase-db psql -U postgres < supabase/migrations/20240115000000_initial_schema.sql
docker exec -i mediavelichie-supabase-db psql -U postgres < supabase/migrations/20240115000001_sample_data.sql
docker exec -i mediavelichie-supabase-db psql -U postgres < supabase/migrations/20240115000002_add_description_to_portfolio.sql
```

Или примените все миграции одной командой:

```bash
for migration in supabase/migrations/*.sql; do
    echo "Применение: $migration"
    docker exec -i mediavelichie-supabase-db psql -U postgres < "$migration"
done
```

## Использование с docker-compose.prod.yml

После установки локального Supabase, вы можете запустить все сервисы:

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml up -d
```

Это запустит:
- ✅ Supabase (PostgreSQL)
- ✅ Frontend (Nginx)
- ✅ Editor (Flask)

## Решение проблем

### Контейнер не запускается

1. Проверьте логи:
   ```bash
   docker logs mediavelichie-supabase-db
   ```

2. Проверьте, не занят ли порт 5432:
   ```bash
   ss -tlnp | grep 5432
   ```

3. Проверьте доступное место на диске:
   ```bash
   df -h
   ```

### Ошибка подключения

1. Убедитесь, что контейнер запущен:
   ```bash
   docker ps | grep supabase
   ```

2. Проверьте правильность IP адреса в `SUPABASE_URL`:
   ```bash
   grep SUPABASE_URL .env
   ```

3. Проверьте доступность порта:
   ```bash
   curl -v http://localhost:5432
   ```

### Проблемы с JWT токенами

Если токены не работают, перегенерируйте их:

```bash
cd /opt/mediavelichia
./setup-local-supabase.sh
```

Скрипт безопасно обновит только отсутствующие значения.

## Безопасность

⚠️ **Важно:**

- Файл `.env` содержит секретные данные и **НЕ должен** попадать в Git
- `SUPABASE_SERVICE_KEY` имеет полные права доступа - **НЕ используйте** его в frontend коде
- Регулярно делайте резервные копии базы данных
- Для продакшена рекомендуется использовать облачный Supabase

## Резервное копирование

### Создание бэкапа

```bash
docker exec mediavelichie-supabase-db pg_dump -U postgres postgres > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление из бэкапа

```bash
docker exec -i mediavelichie-supabase-db psql -U postgres < backup_20240126_120000.sql
```

## Дополнительная информация

- Документация Supabase: https://supabase.com/docs
- Docker Compose документация: https://docs.docker.com/compose/
- PostgreSQL документация: https://www.postgresql.org/docs/
