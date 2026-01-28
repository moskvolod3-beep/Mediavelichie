# Проверка портов и доступности сервисов

## Проблема: Ошибка 500 на порту 5432

Порт `5432` - это порт **PostgreSQL базы данных**, а не веб-сервер. Через браузер к нему подключиться нельзя.

## Правильные порты для доступа

### Веб-сайт
- **HTTP:** `http://194.58.88.127` или `http://medvel.ru` (порт 80)
- **HTTPS:** `https://medvel.ru` (порт 443, если настроен SSL)

### Supabase

**Важно:** В вашем `docker-compose.prod.yml` нет полного Supabase стека с API!

Текущая конфигурация содержит только:
- PostgreSQL база данных (порт 5432) - **не доступна через браузер**
- Supabase Studio (порт 3000) - веб-интерфейс для управления БД

**Для работы Storage API и REST API нужен:**
- Облачный Supabase: `https://your-project-id.supabase.co`
- Или полный локальный Supabase стек с Kong Gateway (порт 54321)

### Editor (Flask)
- **HTTP:** `http://194.58.88.127:5000`

## Проверка запущенных сервисов

```bash
# Проверьте какие контейнеры запущены
docker ps

# Проверьте какие порты открыты
netstat -tulpn | grep LISTEN
# или
ss -tulpn | grep LISTEN
```

## Проверка доступности сервисов

```bash
# Проверка веб-сайта (должен работать)
curl -I http://194.58.88.127
# Ожидается: HTTP/1.1 200 OK

# Проверка Supabase Studio (если запущен)
curl -I http://194.58.88.127:3000
# Ожидается: HTTP/1.1 200 OK или 302 Redirect

# Проверка Editor (если запущен)
curl -I http://194.58.88.127:5000
# Ожидается: HTTP/1.1 200 OK

# Проверка PostgreSQL (через psql, не через браузер!)
docker exec -it mediavelichie-supabase-db psql -U postgres -c "SELECT version();"
```

## Почему порт 5432 не работает через браузер?

Порт 5432 - это **порт базы данных PostgreSQL**. Он:
- Использует протокол PostgreSQL (не HTTP)
- Требует специального клиента (psql, pgAdmin, и т.д.)
- Не предназначен для доступа через браузер

Попытка открыть `http://194.58.88.127:5432` в браузере приведет к ошибке, так как браузер ожидает HTTP ответ, а получает PostgreSQL протокол.

## Правильный доступ к Supabase

### Если используете облачный Supabase (рекомендуется):

1. **REST API:** `https://your-project-id.supabase.co/rest/v1/`
2. **Storage API:** `https://your-project-id.supabase.co/storage/v1/`
3. **Dashboard:** https://supabase.com/dashboard

### Если используете локальный Supabase Studio:

**Веб-интерфейс:** `http://194.58.88.127:3000`

Но для работы Storage API и REST API нужен полный Supabase стек с Kong Gateway на порту 54321.

## Проверка конфигурации

```bash
# Проверьте какие сервисы определены в docker-compose
docker compose -f docker-compose.prod.yml config --services

# Проверьте статус всех сервисов
docker compose -f docker-compose.prod.yml ps

# Проверьте логи если есть проблемы
docker compose -f docker-compose.prod.yml logs web
docker compose -f docker-compose.prod.yml logs supabase-studio
```

## Решение проблемы с Supabase URL

Если вам нужен доступ к Supabase API, используйте **облачный Supabase**:

1. Создайте проект на https://supabase.com
2. Получите Project URL из Settings → API
3. Обновите `.env` файл:
   ```bash
   nano .env
   # Измените:
   SUPABASE_URL=https://your-project-id.supabase.co
   ```
4. Пересоберите контейнер:
   ```bash
   docker compose -f docker-compose.prod.yml build web
   docker compose -f docker-compose.prod.yml up -d web
   ```

## Полезные команды

```bash
# Просмотр всех открытых портов
ss -tulpn | grep LISTEN

# Проверка конкретного порта
nc -zv 194.58.88.127 80
nc -zv 194.58.88.127 3000
nc -zv 194.58.88.127 5000

# Проверка через curl
curl -I http://194.58.88.127
curl -I http://194.58.88.127:3000
curl -I http://194.58.88.127:5000
```
