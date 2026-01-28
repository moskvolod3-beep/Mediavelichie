# Исправление локальных URL для работы на сервере

## Проблема

Все фото и видео ссылаются на локальный контейнер (`http://127.0.0.1:54321` или `http://localhost:54321`), который работает только на вашем компьютере. На сервере эти ссылки не работают.

## Решение

### Вариант 1: Автоматическая замена при сборке Docker (рекомендуется)

Dockerfile автоматически заменяет локальные URL на серверные при сборке образа, если переданы переменные окружения.

**На сервере:**

1. Убедитесь, что в `.env` файле указан правильный Supabase URL:

```bash
cd /opt/mediavelichia
cat .env | grep SUPABASE_URL
```

Если используется облачный Supabase, URL должен быть вида:
```
SUPABASE_URL=https://your-project-id.supabase.co
```

Если используется локальный Supabase на сервере, URL должен быть:
```
SUPABASE_URL=http://194.58.88.127:54321
```

2. Пересоберите Docker контейнер:

```bash
docker compose -f docker-compose.prod.yml build web
docker compose -f docker-compose.prod.yml up -d web
```

### Вариант 2: Использование скрипта замены

Если нужно заменить URL в исходных файлах перед коммитом:

**На локальном компьютере:**

```bash
# Укажите URL вашего Supabase (облачный или серверный)
./replace-localhost-urls.sh https://your-project-id.supabase.co

# Или для локального Supabase на сервере:
./replace-localhost-urls.sh http://194.58.88.127:54321
```

Скрипт автоматически:
- Заменит все `http://127.0.0.1:54321` на указанный URL
- Заменит все `http://localhost:54321` на указанный URL
- Обновит конфигурационные файлы
- Создаст резервные копии (.bak файлы)

После замены проверьте изменения и удалите .bak файлы:

```bash
# Просмотр изменений
git diff

# Удаление резервных копий
find frontend -name "*.bak" -delete
```

### Вариант 3: Ручная замена через sed

Если нужно заменить вручную на сервере:

```bash
cd /opt/mediavelichia/frontend

# Замена в HTML файлах
find . -name "*.html" -type f -exec sed -i "s|http://127.0.0.1:54321|https://your-project-id.supabase.co|g" {} \;
find . -name "*.html" -type f -exec sed -i "s|http://localhost:54321|https://your-project-id.supabase.co|g" {} \;

# Замена в JavaScript файлах
find js -name "*.js" -type f -exec sed -i "s|http://127.0.0.1:54321|https://your-project-id.supabase.co|g" {} \;
find js -name "*.js" -type f -exec sed -i "s|http://localhost:54321|https://your-project-id.supabase.co|g" {} \;

# Обновление конфигурации
sed -i "s|http://127.0.0.1:54321|https://your-project-id.supabase.co|g" supabase/config.js
```

## Проверка

После замены проверьте:

1. **Откройте сайт в браузере:**
   ```
   http://medvel.ru
   ```

2. **Откройте консоль разработчика (F12) и проверьте:**
   - Нет ли ошибок загрузки изображений/видео
   - Все ли URL указывают на правильный Supabase

3. **Проверьте сетевые запросы:**
   - В DevTools → Network проверьте, что запросы идут на правильный домен
   - Не должно быть запросов к `127.0.0.1` или `localhost`

## Какой Supabase URL использовать?

### Облачный Supabase (рекомендуется для продакшена)

Если вы используете облачный Supabase:
```
SUPABASE_URL=https://your-project-id.supabase.co
```

Преимущества:
- Надежность и масштабируемость
- Автоматические бэкапы
- Глобальная CDN для быстрой загрузки

### Локальный Supabase на сервере

Если вы используете локальный Supabase контейнер на сервере:
```
SUPABASE_URL=http://194.58.88.127:54321
```

**Важно:** Убедитесь, что порт 54321 открыт в firewall, если нужен внешний доступ.

## Обновление .env файла

На сервере обновите `.env` файл:

```bash
cd /opt/mediavelichia
nano .env
```

Убедитесь, что указаны правильные значения:

```env
# Для облачного Supabase
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Или для локального Supabase на сервере
SUPABASE_URL=http://194.58.88.127:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

После обновления пересоберите контейнер:

```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build web
docker compose -f docker-compose.prod.yml up -d
```

## Устранение проблем

### Изображения/видео не загружаются

1. Проверьте, что Supabase URL правильный:
   ```bash
   curl -I https://your-project-id.supabase.co/storage/v1/object/public/portfolio/...
   ```

2. Проверьте консоль браузера на ошибки CORS

3. Убедитесь, что файлы загружены в Supabase Storage

### Все еще используются localhost URL

1. Очистите кеш браузера (Ctrl+Shift+Delete)

2. Пересоберите Docker контейнер:
   ```bash
   docker compose -f docker-compose.prod.yml build --no-cache web
   docker compose -f docker-compose.prod.yml up -d web
   ```

3. Проверьте, что переменные окружения переданы правильно:
   ```bash
   docker exec mediavelichie-web env | grep SUPABASE
   ```

## Автоматизация

Для автоматической замены при каждом деплое добавьте в скрипт деплоя:

```bash
# В rebuild-images-on-server.sh или restart-and-check.sh
cd /opt/mediavelichia
./replace-localhost-urls.sh "$SUPABASE_URL"
docker compose -f docker-compose.prod.yml build web
docker compose -f docker-compose.prod.yml up -d web
```
