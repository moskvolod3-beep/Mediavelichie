# Быстрое исправление локальных URL

## Проблема
Все фото и видео ссылаются на `http://127.0.0.1:54321` (локальный компьютер), а нужно чтобы они работали на сервере.

## Решение на сервере

### Шаг 1: Проверьте .env файл

```bash
cd /opt/mediavelichia
cat .env | grep SUPABASE_URL
```

Убедитесь, что указан правильный Supabase URL:

**Для облачного Supabase:**
```
SUPABASE_URL=https://your-project-id.supabase.co
```

**Для локального Supabase на сервере:**
```
SUPABASE_URL=http://194.58.88.127:54321
```

### Шаг 2: Пересоберите контейнер

```bash
cd /opt/mediavelichia

# Получите последние изменения
git pull origin main

# Убедитесь что .env файл содержит правильный SUPABASE_URL
cat .env | grep SUPABASE_URL

# Пересоберите контейнер (Dockerfile автоматически заменит все localhost URL)
# Важно: переменные из .env автоматически передаются в Docker build
docker compose -f docker-compose.prod.yml build web

# Перезапустите контейнер
docker compose -f docker-compose.prod.yml up -d web
```

**Важно:** Убедитесь, что в `.env` файле указан правильный `SUPABASE_URL`, иначе замена не произойдет!

### Шаг 3: Проверьте результат

1. Откройте сайт: http://medvel.ru
2. Откройте консоль браузера (F12)
3. Проверьте, что нет ошибок загрузки изображений/видео
4. В Network вкладке убедитесь, что запросы идут на правильный Supabase URL (не на localhost)

## Если все еще не работает

### Вариант A: Проверить и исправить в запущенном контейнере

```bash
cd /opt/mediavelichia

# Получите скрипт
git pull origin main
chmod +x verify-and-fix-urls.sh

# Проверьте и исправьте URL в запущенном контейнере
./verify-and-fix-urls.sh

# Или укажите URL вручную
./verify-and-fix-urls.sh https://your-project-id.supabase.co
```

Это временное решение - изменения будут потеряны при пересборке контейнера.

### Вариант B: Использовать скрипт замены в исходниках

```bash
cd /opt/mediavelichia

# Сделайте скрипт исполняемым
chmod +x replace-localhost-urls.sh

# Запустите замену (укажите ваш Supabase URL)
./replace-localhost-urls.sh https://your-project-id.supabase.co

# Пересоберите контейнер
docker compose -f docker-compose.prod.yml build web
docker compose -f docker-compose.prod.yml up -d web
```

### Вариант B: Ручная замена

```bash
cd /opt/mediavelichia/frontend

# Замена в HTML файлах
find . -name "*.html" -exec sed -i "s|http://127.0.0.1:54321|https://your-project-id.supabase.co|g" {} \;
find . -name "*.html" -exec sed -i "s|http://localhost:54321|https://your-project-id.supabase.co|g" {} \;

# Замена в JS файлах
find js -name "*.js" -exec sed -i "s|http://127.0.0.1:54321|https://your-project-id.supabase.co|g" {} \;
find js -name "*.js" -exec sed -i "s|http://localhost:54321|https://your-project-id.supabase.co|g" {} \;

# Пересоберите контейнер
cd ..
docker compose -f docker-compose.prod.yml build web
docker compose -f docker-compose.prod.yml up -d web
```

## Как узнать свой Supabase URL?

### Если используете облачный Supabase:
1. Зайдите на https://supabase.com
2. Откройте ваш проект
3. Settings → API
4. Скопируйте "Project URL"

### Если используете локальный Supabase на сервере:
URL будет: `http://194.58.88.127:54321`

Но убедитесь, что Supabase Studio запущен и доступен на порту 3000:
```bash
docker ps | grep supabase
```

## Проверка после исправления

```bash
# Проверьте логи контейнера
docker logs mediavelichie-web | tail -20

# Проверьте что контейнер запущен
docker ps | grep mediavelichie-web

# Проверьте доступность сайта
curl -I http://medvel.ru
```

Подробная инструкция: `FIX_LOCALHOST_URLS.md`
