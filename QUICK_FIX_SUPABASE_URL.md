# Быстрое исправление Supabase URL

## Проблема

В `.env` файле указан неправильный порт:
```
SUPABASE_URL=http://194.58.88.127:5432
```

Порт `5432` - это PostgreSQL база данных, а не Supabase API.

## Быстрое решение

### На сервере выполните:

```bash
cd /opt/mediavelichia

# Вариант 1: Использовать скрипт (рекомендуется)
git pull origin main
chmod +x fix-supabase-url.sh
./fix-supabase-url.sh https://your-project-id.supabase.co

# Вариант 2: Исправить вручную
nano .env
# Измените строку:
# SUPABASE_URL=http://194.58.88.127:5432
# На:
# SUPABASE_URL=https://your-project-id.supabase.co
# Сохраните (Ctrl+O, Enter, Ctrl+X)
```

### После исправления:

```bash
# Пересоберите контейнер с правильным URL
docker compose -f docker-compose.prod.yml build web

# Перезапустите контейнер
docker compose -f docker-compose.prod.yml up -d web

# Проверьте что URL заменился
docker exec mediavelichie-web cat /usr/share/nginx/html/supabase/config.js | grep url
```

## Как узнать свой Supabase URL?

### Если используете облачный Supabase:

1. Зайдите на https://supabase.com
2. Откройте ваш проект
3. Settings → API
4. Скопируйте "Project URL" (например: `https://xxxxxxxxxxxxx.supabase.co`)

### Если хотите использовать локальный Supabase:

⚠️ **Проблема:** В текущем `docker-compose.prod.yml` нет полного Supabase стека с API.

Текущая конфигурация содержит только PostgreSQL и Studio, но нет:
- Kong Gateway (для REST API на порту 54321)
- Storage API
- PostgREST

**Рекомендация:** Используйте облачный Supabase для продакшена - это проще и надежнее.

## Проверка после исправления

```bash
# Проверьте что URL правильный в .env
cat .env | grep SUPABASE_URL

# Проверьте что URL заменился в контейнере
docker exec mediavelichie-web cat /usr/share/nginx/html/supabase/config.js

# Проверьте доступность Supabase API
curl -I $(cat .env | grep SUPABASE_URL | cut -d '=' -f2)/rest/v1/
```

Если получаете `200 OK` или `401 Unauthorized` (это нормально без токена) - значит URL правильный.

Если получаете `Connection refused` или `ERR_CONNECTION_REFUSED` - проверьте URL.
