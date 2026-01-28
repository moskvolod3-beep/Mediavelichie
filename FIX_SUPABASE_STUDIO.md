# Исправление подключения Supabase Studio к PostgreSQL

## Проблема

Supabase Studio на порту 3000 не видит базу данных на порту 5432.

## Причины

1. **Несовпадение паролей** - пароль в Studio не совпадает с паролем в PostgreSQL
2. **Проблемы с сетью Docker** - контейнеры не могут общаться друг с другом
3. **Неправильные переменные окружения** - Studio не получает правильные параметры подключения

## Решение

### Шаг 1: Проверка паролей

```bash
cd /opt/mediavelichia

# Проверьте пароль в .env файле
cat .env | grep POSTGRES_PASSWORD

# Проверьте пароль в контейнере PostgreSQL
docker exec mediavelichie-supabase-db env | grep POSTGRES_PASSWORD

# Проверьте пароль в контейнере Studio
docker exec mediavelichie-supabase-studio env | grep POSTGRES_PASSWORD
```

Пароли должны совпадать!

### Шаг 2: Проверка сети Docker

```bash
# Проверьте что оба контейнера в одной сети
docker network inspect mediavelichie-network | grep -A 5 "Containers"

# Проверьте подключение из Studio к БД
docker exec mediavelichie-supabase-studio ping -c 2 supabase
```

### Шаг 3: Исправление конфигурации

Обновите `docker-compose.prod.yml` и перезапустите:

```bash
cd /opt/mediavelichia

# Получите обновления
git pull origin main

# Перезапустите Studio с новой конфигурацией
docker compose -f docker-compose.prod.yml up -d supabase-studio

# Проверьте логи
docker logs mediavelichie-supabase-studio
```

### Шаг 4: Использование скрипта диагностики

```bash
chmod +x fix-supabase-studio-connection.sh
./fix-supabase-studio-connection.sh
```

## Ручное исправление

Если автоматическое исправление не помогло:

### Вариант 1: Убедитесь что пароль правильный

```bash
# Отредактируйте .env файл
nano .env

# Убедитесь что POSTGRES_PASSWORD одинаковый везде
# Перезапустите контейнеры
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### Вариант 2: Проверьте подключение вручную

```bash
# Из контейнера Studio попробуйте подключиться к БД
docker exec -it mediavelichie-supabase-studio sh

# Внутри контейнера:
# Установите psql если нет
apk add postgresql-client

# Подключитесь к БД
psql -h supabase -U postgres -d postgres
# Введите пароль из .env файла
```

### Вариант 3: Используйте прямой доступ к БД

Если Studio не работает, используйте прямой доступ:

```bash
# Подключение через Docker exec
docker exec -it mediavelichie-supabase-db psql -U postgres

# Или через psql клиент (если установлен на сервере)
psql -h 194.58.88.127 -p 5432 -U postgres -d postgres
```

## Проверка после исправления

1. Откройте Supabase Studio: http://194.58.88.127:3000
2. При запросе данных подключения используйте:
   - **Host:** `supabase` (внутри Docker) или `194.58.88.127` (снаружи)
   - **Port:** `5432`
   - **Database:** `postgres`
   - **User:** `postgres`
   - **Password:** из `.env` файла

## Альтернативное решение

Если Studio все еще не работает, используйте **облачный Supabase** для продакшена:

1. Создайте проект на https://supabase.com
2. Используйте облачный Studio вместо локального
3. Обновите `.env` с облачным Supabase URL

Это более надежное решение для продакшена.
