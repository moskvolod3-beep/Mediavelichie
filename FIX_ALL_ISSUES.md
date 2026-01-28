# Исправление всех проблем перед деплоем

## Текущие проблемы

1. ❌ **Ошибка синтаксиса YAML** в `docker-compose.prod.cloud.yml`
2. ❌ **SUPABASE_URL** не настроен (содержит placeholder)
3. ❌ **SUPABASE_ANON_KEY** не настроен (содержит placeholder)
4. ⚠️ **SUPABASE_SERVICE_KEY** не настроен (нужен для backend)
5. ⚠️ **SUPABASE_BUCKET** не настроен (будет использован 'portfolio' по умолчанию)

## Пошаговое исправление

### Шаг 1: Обновить код из репозитория

```bash
cd /opt/mediavelichia
git pull origin main
```

Это исправит ошибку YAML синтаксиса.

### Шаг 2: Проверить синтаксис YAML

```bash
docker compose -f docker-compose.prod.cloud.yml config
```

Если команда выполнилась без ошибок, синтаксис исправлен.

### Шаг 3: Настроить переменные окружения

Отредактируйте файл `.env`:

```bash
nano /opt/mediavelichia/.env
```

Или используйте `vi`:

```bash
vi /opt/mediavelichia/.env
```

#### Обязательные переменные для облачного Supabase:

```bash
# URL вашего Supabase проекта
SUPABASE_URL=https://ваш-проект.supabase.co

# Anon public key (для frontend)
SUPABASE_ANON_KEY=ваш-anon-public-key

# Service role key (для backend/editor)
SUPABASE_SERVICE_KEY=ваш-service-role-key

# Storage bucket для портфолио (опционально, по умолчанию 'portfolio')
SUPABASE_BUCKET=portfolio
```

#### Где взять эти значения:

1. **SUPABASE_URL** и **SUPABASE_ANON_KEY**:
   - Зайдите на https://supabase.com
   - Откройте ваш проект
   - Перейдите в **Settings → API**
   - Скопируйте **Project URL** → это `SUPABASE_URL`
   - Скопируйте **anon public** key → это `SUPABASE_ANON_KEY`

2. **SUPABASE_SERVICE_KEY**:
   - В том же разделе **Settings → API**
   - Скопируйте **service_role** key → это `SUPABASE_SERVICE_KEY`
   - ⚠️ **ВАЖНО**: Этот ключ имеет полные права доступа. НЕ используйте его в frontend коде!

3. **SUPABASE_BUCKET**:
   - По умолчанию используется `portfolio`
   - Если у вас другой bucket, укажите его имя

### Шаг 4: Проверить настройки

После редактирования `.env`, проверьте что переменные установлены:

```bash
cd /opt/mediavelichia
source .env 2>/dev/null || true
echo "SUPABASE_URL: ${SUPABASE_URL:0:30}..."
echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:30}..."
echo "SUPABASE_SERVICE_KEY: ${SUPABASE_SERVICE_KEY:0:30}..."
```

### Шаг 5: Повторная проверка готовности

Запустите скрипт проверки еще раз:

```bash
cd /opt/mediavelichia
./check-deployment-ready.sh
```

Все проверки должны пройти успешно.

### Шаг 6: Запуск контейнеров

Если все проверки пройдены:

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.cloud.yml up -d --build
```

### Шаг 7: Проверка статуса

```bash
# Статус контейнеров
docker compose -f docker-compose.prod.cloud.yml ps

# Логи (последние 50 строк)
docker compose -f docker-compose.prod.cloud.yml logs --tail=50

# Проверка работы веб-сервера
curl http://localhost/
```

## Быстрое исправление (одной командой)

Если у вас уже есть значения для Supabase, выполните:

```bash
cd /opt/mediavelichia && \
git pull origin main && \
nano .env
```

Затем заполните переменные и запустите:

```bash
docker compose -f docker-compose.prod.cloud.yml config && \
docker compose -f docker-compose.prod.cloud.yml up -d --build
```

## Проверка после исправления

После исправления всех проблем, скрипт проверки должен показать:

```
✓ Все проверки пройдены успешно!
```

## Дополнительная информация

- Подробные инструкции по настройке Supabase: см. `DEPLOY.md` и `SUPABASE_SETUP.md`
- Исправление YAML ошибки: см. `FIX_YAML_ERROR.md`
- Общая документация по деплою: см. `DEPLOY.md`
