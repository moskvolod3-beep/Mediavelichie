# Немедленное исправление URL в контейнере

## Проблема

После пересборки контейнера URL все еще показывает `http://194.58.88.127:5432` вместо правильного Supabase URL.

## Быстрое решение (исправить прямо в контейнере)

```bash
cd /opt/mediavelichia

# Получите скрипт
git pull origin main
chmod +x fix-url-in-container.sh

# Исправьте URL в запущенном контейнере
# Укажите ваш облачный Supabase URL:
./fix-url-in-container.sh https://your-project-id.supabase.co

# Или для локального Supabase (если настроен полный стек):
./fix-url-in-container.sh http://194.58.88.127:54321
```

Это временное решение - изменения будут потеряны при пересборке контейнера.

## Постоянное решение (исправить .env и пересобрать)

```bash
cd /opt/mediavelichia

# 1. Исправьте .env файл
nano .env
# Измените:
# SUPABASE_URL=http://194.58.88.127:5432
# На правильный URL:
# SUPABASE_URL=https://your-project-id.supabase.co

# Или используйте скрипт:
chmod +x fix-supabase-url.sh
./fix-supabase-url.sh https://your-project-id.supabase.co

# 2. Проверьте что URL правильный
cat .env | grep SUPABASE_URL

# 3. Пересоберите контейнер (важно: используйте --build-arg или убедитесь что .env читается)
docker compose -f docker-compose.prod.yml build --no-cache web

# 4. Перезапустите
docker compose -f docker-compose.prod.yml up -d web

# 5. Проверьте что URL заменился
docker exec mediavelichie-web cat /usr/share/nginx/html/supabase/config.js | grep url
```

## Почему URL не заменился при сборке?

Возможные причины:
1. Переменная `SUPABASE_URL` пустая или неправильная в `.env`
2. Docker Compose не читает `.env` файл при build
3. Переменная не передается как build arg

## Проверка

```bash
# Проверьте что в .env правильный URL
cat .env | grep SUPABASE_URL

# Проверьте что переменная доступна
docker compose -f docker-compose.prod.yml config | grep SUPABASE_URL

# Если переменная не видна, попробуйте явно указать:
SUPABASE_URL=https://your-project-id.supabase.co docker compose -f docker-compose.prod.yml build web
```

## Альтернатива: исправить вручную в контейнере

Если скрипт не работает, исправьте вручную:

```bash
# Замените URL в config.js
docker exec mediavelichie-web sed -i "s|http://194.58.88.127:5432|https://your-project-id.supabase.co|g" /usr/share/nginx/html/supabase/config.js

# Замените во всех HTML файлах
docker exec mediavelichie-web find /usr/share/nginx/html -name "*.html" -exec sed -i "s|http://194.58.88.127:5432|https://your-project-id.supabase.co|g" {} \;

# Замените во всех JS файлах
docker exec mediavelichie-web find /usr/share/nginx/html -name "*.js" -exec sed -i "s|http://194.58.88.127:5432|https://your-project-id.supabase.co|g" {} \;

# Перезагрузите Nginx (если нужно)
docker exec mediavelichie-web nginx -s reload
```

## После исправления

1. Откройте сайт в браузере: http://medvel.ru
2. Откройте консоль разработчика (F12)
3. Проверьте что нет ошибок `ERR_CONNECTION_REFUSED`
4. Проверьте что запросы идут на правильный Supabase URL
