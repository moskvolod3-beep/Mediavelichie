# Следующие шаги после установки Supabase

## ✅ Что уже сделано

- ✅ Локальный Supabase контейнер установлен и запущен
- ✅ Переменные окружения настроены в `.env`
- ✅ Данные для подключения сгенерированы

## 📋 Следующие шаги

### 1. Применить миграции базы данных

```bash
cd /opt/mediavelichia

# Делаем скрипт исполняемым
chmod +x apply-migrations.sh

# Применяем миграции
./apply-migrations.sh
```

Или вручную:

```bash
cd /opt/mediavelichia

# Применяем каждую миграцию
docker exec -i mediavelichie-supabase-db psql -U postgres < backend/supabase/migrations/20240115000000_initial_schema.sql
docker exec -i mediavelichie-supabase-db psql -U postgres < backend/supabase/migrations/20240115000001_sample_data.sql
docker exec -i mediavelichie-supabase-db psql -U postgres < backend/supabase/migrations/20240115000002_add_description_to_portfolio.sql
```

### 2. Проверить работу Supabase

```bash
# Проверка статуса контейнера
docker ps | grep supabase

# Проверка подключения к БД
docker exec mediavelichie-supabase-db pg_isready -U postgres

# Подключение к базе данных
docker exec -it mediavelichie-supabase-db psql -U postgres

# В psql можно выполнить:
# \dt          - список таблиц
# \d portfolio - структура таблицы portfolio
# SELECT * FROM portfolio LIMIT 5; - пример запроса
# \q           - выход
```

### 3. Запустить все сервисы

После применения миграций можно запустить все сервисы:

```bash
cd /opt/mediavelichia

# Запуск всех сервисов (web, supabase, editor)
docker compose -f docker-compose.prod.yml up -d --build

# Проверка статуса всех контейнеров
docker compose -f docker-compose.prod.yml ps

# Просмотр логов
docker compose -f docker-compose.prod.yml logs -f
```

### 4. Проверить работу сайта

После запуска всех сервисов:

```bash
# Проверка веб-сервера
curl http://localhost/

# Проверка Editor сервера
curl http://localhost:5000/health

# Проверка доступности с внешнего IP
curl http://194.58.88.127/
```

## 📊 Текущие данные подключения

Из вывода скрипта установки:

```
SUPABASE_URL=http://194.58.88.127:5432
SUPABASE_ANON_KEY=eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9...

База данных:
Host: 194.58.88.127
Port: 5432
Database: postgres
User: postgres
Password: yNtGMC35GnqF8Od9PMZSDrKRR0I6jFJ2
```

Все эти данные сохранены в файле `/opt/mediavelichia/.env`

## 🔍 Проверка готовности к запуску

Выполните проверку готовности:

```bash
cd /opt/mediavelichia
./check-deployment-ready.sh
```

После применения миграций все проверки должны пройти успешно.

## 🚀 Быстрый запуск всех сервисов

```bash
cd /opt/mediavelichia

# 1. Применить миграции (если еще не применены)
./apply-migrations.sh

# 2. Запустить все сервисы
docker compose -f docker-compose.prod.yml up -d --build

# 3. Проверить статус
docker compose -f docker-compose.prod.yml ps

# 4. Просмотреть логи
docker compose -f docker-compose.prod.yml logs --tail=50
```

## 📝 Важные замечания

1. **Миграции** нужно применить только один раз после первой установки
2. **Данные БД** хранятся в Docker volume `supabase-db-data` и сохраняются при перезапуске контейнера
3. **Пароли и ключи** хранятся в `.env` - не коммитьте этот файл в Git
4. **Для продакшена** рекомендуется использовать облачный Supabase (`docker-compose.prod.cloud.yml`)

## 🆘 Решение проблем

Если что-то не работает:

1. Проверьте логи контейнеров:
   ```bash
   docker logs mediavelichie-supabase-db
   docker logs mediavelichie-web
   docker logs mediavelichie-editor
   ```

2. Проверьте статус контейнеров:
   ```bash
   docker ps -a
   ```

3. Перезапустите контейнеры:
   ```bash
   docker compose -f docker-compose.prod.yml restart
   ```
