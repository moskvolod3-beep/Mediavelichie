# Инструкции по деплою Mediavelichia

Полное руководство по развертыванию проекта на продакшен сервере.

## Содержание

1. [Подготовка сервера](#подготовка-сервера)
2. [Настройка Supabase](#настройка-supabase)
3. [Настройка переменных окружения](#настройка-переменных-окружения)
4. [Ручной деплой через Docker](#ручной-деплой-через-docker)
5. [Автоматический деплой через GitHub Actions](#автоматический-деплой-через-github-actions)
6. [Проверка работоспособности](#проверка-работоспособности)
7. [Обновление проекта](#обновление-проекта)
8. [Устранение неполадок](#устранение-неполадок)

---

## Подготовка сервера

### Требования

- Ubuntu/Debian сервер с доступом по SSH
- Минимум 2 GB RAM
- Минимум 10 GB свободного места на диске
- Открытые порты: 80 (HTTP), 443 (HTTPS), 22 (SSH)

### Установка Docker и Docker Compose

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Добавление официального GPG ключа Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Определение версии ОС
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Проверка установки
docker --version
docker compose version

# Добавление пользователя в группу docker (опционально, чтобы не использовать sudo)
sudo usermod -aG docker $USER
# После этого нужно перелогиниться
```

### Подготовка директории проекта

```bash
# Создание директории проекта
sudo mkdir -p /opt/mediavelichia
sudo chown $USER:$USER /opt/mediavelichia
cd /opt/mediavelichia
```

---

## Настройка Supabase

У вас есть два варианта: использовать облачный Supabase (рекомендуется) или локальный контейнер.

### Вариант 1: Облачный Supabase (рекомендуется)

1. **Создайте проект на Supabase:**
   - Перейдите на https://supabase.com
   - Создайте новый проект
   - Запомните Project URL и API ключи

2. **Настройте базу данных:**
   - Перейдите в SQL Editor
   - Выполните миграции из `backend/supabase/migrations/` (если есть)

3. **Настройте Storage:**
   - Перейдите в Storage
   - Создайте bucket с именем `portfolio` (или укажите другое имя в `.env`)
   - Настройте политики доступа (public read для портфолио)

4. **Получите API ключи:**
   - Settings → API
   - Скопируйте:
     - Project URL
     - `anon` `public` key (для фронтенда)
     - `service_role` `secret` key (для бэкенда, НЕ используйте в фронтенде!)

### Вариант 2: Локальный Supabase

Используйте `docker-compose.prod.yml` - он включает локальный контейнер Supabase.

**Важно:** Для продакшена рекомендуется использовать облачный Supabase для лучшей производительности и надежности.

---

## Настройка переменных окружения

1. **Создайте файл `.env` на сервере:**

```bash
cd /opt/mediavelichia
nano .env
```

2. **Заполните переменные (для облачного Supabase):**

```bash
# Supabase (облачный)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key-here
SUPABASE_SERVICE_KEY=your-service-role-key-here
SUPABASE_BUCKET=portfolio

# Если используете локальный Supabase, добавьте также:
# POSTGRES_PASSWORD=your-super-secret-postgres-password-change-me
# JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long-change-me
```

3. **Сохраните файл** (Ctrl+O, Enter, Ctrl+X в nano)

4. **Убедитесь, что файл не попал в Git:**

```bash
# Проверьте, что .env в .gitignore
grep "^\.env$" .gitignore || echo ".env" >> .gitignore
```

---

## Ручной деплой через Docker

### Шаг 1: Клонирование репозитория

```bash
cd /opt/mediavelichia

# Если репозиторий еще не клонирован
git clone https://github.com/moskvolod3-beep/Mediavelichie.git .

# Или обновление существующего репозитория
git pull origin main
```

### Шаг 2: Выбор конфигурации

**Для облачного Supabase:**
```bash
COMPOSE_FILE=docker-compose.prod.cloud.yml
```

**Для локального Supabase:**
```bash
COMPOSE_FILE=docker-compose.prod.yml
```

### Шаг 3: Сборка и запуск контейнеров

```bash
# Остановка старых контейнеров (если есть)
docker compose -f $COMPOSE_FILE down

# Сборка и запуск
docker compose -f $COMPOSE_FILE up -d --build

# Просмотр логов
docker compose -f $COMPOSE_FILE logs -f
```

### Шаг 4: Проверка статуса

```bash
# Статус контейнеров
docker compose -f $COMPOSE_FILE ps

# Логи конкретного сервиса
docker compose -f $COMPOSE_FILE logs web
docker compose -f $COMPOSE_FILE logs editor
docker compose -f $COMPOSE_FILE logs supabase  # только для локального Supabase
```

---

## Автоматический деплой через GitHub Actions

### Настройка GitHub Secrets

1. Перейдите в репозиторий на GitHub
2. Settings → Secrets and variables → Actions
3. Добавьте следующие secrets:

```
SERVER_HOST = your-server-ip-address
SERVER_USER = your-ssh-username
SERVER_PORT = 22
SERVER_PATH = /opt/mediavelichia
SERVER_SSH_KEY = содержимое приватного SSH ключа
```

**Как получить SSH ключ:**

```bash
# На локальной машине (если ключа еще нет)
ssh-keygen -t ed25519 -C "deploy@mediavelichia"

# Скопируйте публичный ключ на сервер
ssh-copy-id -i ~/.ssh/id_ed25519.pub your-username@your-server-ip

# Скопируйте приватный ключ в GitHub Secrets
cat ~/.ssh/id_ed25519
```

### Настройка workflow

Workflow уже настроен в `.github/workflows/deploy-docker.yml`. Он автоматически:

1. Собирает Docker образы
2. Копирует файлы на сервер
3. Останавливает старые контейнеры
4. Запускает новые контейнеры

### Запуск деплоя

**Автоматически:** При каждом push в ветку `main`

**Вручную:**
1. Перейдите в Actions на GitHub
2. Выберите "Build and Deploy Docker"
3. Нажмите "Run workflow"
4. Выберите ветку `main`
5. Нажмите "Run workflow"

---

## Проверка работоспособности

### Проверка контейнеров

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.cloud.yml ps
```

Все контейнеры должны быть в статусе `Up` и `healthy`.

### Проверка веб-сайта

```bash
# Проверка доступности фронтенда
curl http://localhost

# Проверка API бэкенда
curl http://localhost:5000/health
```

### Проверка логов

```bash
# Все логи
docker compose -f docker-compose.prod.cloud.yml logs

# Логи конкретного сервиса
docker compose -f docker-compose.prod.cloud.yml logs web
docker compose -f docker-compose.prod.cloud.yml logs editor

# Логи в реальном времени
docker compose -f docker-compose.prod.cloud.yml logs -f web
```

### Проверка портов

```bash
# Проверка открытых портов
sudo netstat -tlnp | grep -E ':(80|443|5000)'
```

---

## Обновление проекта

### Ручное обновление

```bash
cd /opt/mediavelichia

# Обновление кода
git pull origin main

# Пересборка и перезапуск контейнеров
docker compose -f docker-compose.prod.cloud.yml up -d --build

# Очистка старых образов
docker image prune -f
```

### Автоматическое обновление

Просто сделайте `git push` в ветку `main` - GitHub Actions автоматически задеплоит изменения.

---

## Устранение неполадок

### Контейнеры не запускаются

```bash
# Проверка логов
docker compose -f docker-compose.prod.cloud.yml logs

# Проверка статуса
docker compose -f docker-compose.prod.cloud.yml ps

# Перезапуск контейнеров
docker compose -f docker-compose.prod.cloud.yml restart
```

### Проблемы с переменными окружения

```bash
# Проверка, что .env файл существует
ls -la /opt/mediavelichia/.env

# Проверка содержимого (без показа значений)
cat /opt/mediavelichia/.env | grep -v "^#" | grep "="

# Пересоздание .env из примера
cp .env.example .env
nano .env  # Заполните реальными значениями
```

### Проблемы с Supabase

**Для облачного Supabase:**
- Проверьте правильность URL и ключей в `.env`
- Убедитесь, что bucket `portfolio` создан
- Проверьте политики доступа в Storage

**Для локального Supabase:**
```bash
# Проверка статуса контейнера Supabase
docker compose -f docker-compose.prod.yml logs supabase

# Проверка подключения к базе
docker exec -it mediavelichie-supabase-db psql -U postgres -d postgres
```

### Проблемы с портами

```bash
# Проверка, какие процессы используют порты
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :5000

# Остановка конфликтующих процессов
sudo systemctl stop nginx  # если установлен системный nginx
sudo systemctl stop apache2  # если установлен apache
```

### Очистка Docker

```bash
# Остановка всех контейнеров
docker compose -f docker-compose.prod.cloud.yml down

# Удаление неиспользуемых образов
docker image prune -a -f

# Удаление неиспользуемых volumes (ОСТОРОЖНО! Удалит данные)
docker volume prune -f

# Полная очистка (ОСТОРОЖНО!)
docker system prune -a --volumes -f
```

### Просмотр использования ресурсов

```bash
# Использование диска
df -h

# Использование памяти
free -h

# Использование ресурсов контейнерами
docker stats
```

---

## Настройка SSL/HTTPS

### Использование Let's Encrypt (рекомендуется)

1. **Установите Certbot:**

```bash
sudo apt install -y certbot python3-certbot-nginx
```

2. **Получите сертификат:**

```bash
sudo certbot certonly --standalone -d your-domain.com
```

3. **Настройте Nginx:**

Раскомментируйте секцию volumes в `docker-compose.prod.cloud.yml`:

```yaml
volumes:
  - ./ssl:/etc/nginx/ssl:ro
  - ./frontend/nginx.ssl.conf:/etc/nginx/conf.d/default.conf:ro
```

4. **Скопируйте сертификаты:**

```bash
sudo mkdir -p /opt/mediavelichia/ssl
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/mediavelichia/ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /opt/mediavelichia/ssl/
sudo chown -R $USER:$USER /opt/mediavelichia/ssl
```

5. **Перезапустите контейнеры:**

```bash
docker compose -f docker-compose.prod.cloud.yml restart web
```

### Автоматическое обновление сертификата

Добавьте в crontab:

```bash
sudo crontab -e

# Добавьте строку:
0 0 * * * certbot renew --quiet && docker compose -f /opt/mediavelichia/docker-compose.prod.cloud.yml restart web
```

---

## Мониторинг и логи

### Просмотр логов

```bash
# Все логи
docker compose -f docker-compose.prod.cloud.yml logs

# Последние 100 строк
docker compose -f docker-compose.prod.cloud.yml logs --tail=100

# Логи с временными метками
docker compose -f docker-compose.prod.cloud.yml logs -t

# Логи в реальном времени
docker compose -f docker-compose.prod.cloud.yml logs -f
```

### Сохранение логов

```bash
# Сохранение логов в файл
docker compose -f docker-compose.prod.cloud.yml logs > /opt/mediavelichia/logs/$(date +%Y%m%d-%H%M%S).log
```

---

## Резервное копирование

### Резервное копирование базы данных (локальный Supabase)

```bash
# Создание бэкапа
docker exec mediavelichie-supabase-db pg_dump -U postgres postgres > backup_$(date +%Y%m%d).sql

# Восстановление из бэкапа
cat backup_20240126.sql | docker exec -i mediavelichie-supabase-db psql -U postgres postgres
```

### Резервное копирование файлов проекта

```bash
# Создание архива
tar -czf mediavelichia_backup_$(date +%Y%m%d).tar.gz \
    /opt/mediavelichia \
    --exclude='*.git' \
    --exclude='node_modules' \
    --exclude='*.log'
```

---

## Дополнительные ресурсы

- [Документация Docker](https://docs.docker.com/)
- [Документация Docker Compose](https://docs.docker.com/compose/)
- [Документация Supabase](https://supabase.com/docs)
- [Документация Nginx](https://nginx.org/en/docs/)

---

## Поддержка

При возникновении проблем:

1. Проверьте логи контейнеров
2. Убедитесь, что все переменные окружения настроены правильно
3. Проверьте, что порты не заняты другими процессами
4. Убедитесь, что Docker и Docker Compose установлены и работают

---

**Последнее обновление:** 2026-01-26
