# Исправление порта Supabase в .env файле

## Проблема

В `.env` файле указан неправильный порт:
```
SUPABASE_URL=http://194.58.88.127:5432
```

Порт `5432` - это порт PostgreSQL базы данных, а не Supabase API.

## Решение

### Для локального Supabase на сервере

Если вы используете локальный Supabase контейнер, правильный URL должен быть:

```
SUPABASE_URL=http://194.58.88.127:54321
```

**Порты Supabase:**
- `5432` - PostgreSQL база данных (внутренний доступ)
- `54321` - Supabase Studio и REST API (внешний доступ)
- `3000` - Supabase Studio веб-интерфейс

### Для облачного Supabase (рекомендуется)

Если вы используете облачный Supabase, URL должен быть:

```
SUPABASE_URL=https://your-project-id.supabase.co
```

## Исправление на сервере

```bash
cd /opt/mediavelichia

# Отредактируйте .env файл
nano .env

# Измените строку:
# SUPABASE_URL=http://194.58.88.127:5432
# На:
SUPABASE_URL=http://194.58.88.127:54321

# Или для облачного Supabase:
# SUPABASE_URL=https://your-project-id.supabase.co

# Сохраните файл (Ctrl+O, Enter, Ctrl+X)
```

После исправления:

```bash
# Пересоберите контейнер с правильным URL
docker compose -f docker-compose.prod.yml build web

# Перезапустите контейнер
docker compose -f docker-compose.prod.yml up -d web

# Проверьте что URL правильный
docker exec mediavelichie-web cat /usr/share/nginx/html/supabase/config.js | grep url
```

## Проверка доступности Supabase

### Проверка Supabase Studio (порт 54321)

```bash
# Проверьте что контейнер Supabase Studio запущен
docker ps | grep supabase-studio

# Проверьте доступность API
curl -I http://194.58.88.127:54321/rest/v1/
```

Если порт 54321 недоступен, убедитесь что Supabase Studio запущен:

```bash
# Проверьте docker-compose.prod.yml
cat docker-compose.prod.yml | grep -A 10 supabase-studio

# Если контейнер не запущен, запустите его
docker compose -f docker-compose.prod.yml up -d supabase-studio
```

## Важно

Если вы используете **локальный Supabase на сервере**, убедитесь что:

1. Контейнер `mediavelichie-supabase-db` запущен (порт 5432)
2. Контейнер `mediavelichie-supabase-studio` запущен (порт 3000 и API на 54321)
3. Порты открыты в firewall если нужен внешний доступ

Если вы используете **облачный Supabase**, используйте URL вида:
```
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
```

## Быстрая проверка

```bash
# Проверьте текущий URL в .env
cat .env | grep SUPABASE_URL

# Проверьте что Supabase доступен
curl -I $(cat .env | grep SUPABASE_URL | cut -d '=' -f2)/rest/v1/

# Если получаете 200 OK - все правильно
# Если получаете ошибку - проверьте URL и доступность
```
