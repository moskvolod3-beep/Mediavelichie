# Деплой в Docker контейнерах

## Структура проекта

Проект развернут в Docker контейнерах:
- **Web** - статический сайт на Nginx
- **Supabase** - PostgreSQL база данных
- **Supabase Studio** (опционально) - веб-интерфейс для администрирования

## Быстрый старт

### Локальная разработка

1. Скопируйте `.env.example` в `.env`:
   ```bash
   cp .env.example .env
   ```

2. Отредактируйте `.env` и установите безопасные пароли:
   ```bash
   POSTGRES_PASSWORD=ваш-надежный-пароль
   JWT_SECRET=ваш-секретный-jwt-токен-минимум-32-символа
   ```

3. Запустите контейнеры:
   ```bash
   docker-compose up -d
   ```

4. Сайт будет доступен:
   - Веб-сайт: http://localhost
   - Supabase Studio: http://localhost:3000
   - PostgreSQL: localhost:5432

### Остановка

```bash
docker-compose down
```

### Остановка с удалением данных

```bash
docker-compose down -v
```

---

## Продакшен деплой

### Вариант 1: Автоматический деплой через GitHub Actions

**Требования:**
- Сервер с установленным Docker и Docker Compose
- SSH доступ к серверу
- Настроенные GitHub Secrets (см. ниже)

**Настройка GitHub Secrets:**

В репозитории GitHub → Settings → Secrets and variables → Actions добавьте:

- `SERVER_HOST` - IP или домен сервера
- `SERVER_USER` - пользователь SSH
- `SERVER_SSH_KEY` - приватный SSH ключ
- `SERVER_PORT` - порт SSH (обычно 22)
- `SERVER_PATH` - путь на сервере (например: `/opt/mediavelichie`)
- `DOCKER_USERNAME` - (опционально) для Docker Hub
- `DOCKER_PASSWORD` - (опционально) для Docker Hub

**Настройка сервера:**

1. Установите Docker и Docker Compose:
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   sudo usermod -aG docker $USER
   
   # Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. Создайте директорию проекта:
   ```bash
   sudo mkdir -p /opt/mediavelichie
   sudo chown $USER:$USER /opt/mediavelichie
   ```

3. Создайте `.env` файл на сервере:
   ```bash
   cd /opt/mediavelichie
   nano .env
   ```
   
   Добавьте:
   ```env
   POSTGRES_PASSWORD=очень-надежный-пароль-для-продакшена
   JWT_SECRET=очень-длинный-секретный-токен-минимум-32-символа
   ```

4. После настройки GitHub Actions, каждый `git push` будет автоматически деплоить проект.

### Вариант 2: Ручной деплой

1. Склонируйте репозиторий на сервер:
   ```bash
   cd /opt/mediavelichie
   git clone https://github.com/moskvolod3-beep/Mediavelichie.git .
   ```

2. Создайте `.env` файл (см. выше)

3. Запустите контейнеры:
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

4. Проверьте статус:
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   ```

---

## Использование Supabase Cloud вместо локального

Если вы хотите использовать Supabase Cloud вместо локального контейнера:

1. Создайте проект на [supabase.com](https://supabase.com)

2. Получите ключи API из настроек проекта

3. Обновите `.env`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```

4. Удалите сервис `supabase` из `docker-compose.yml` или закомментируйте его

5. В вашем JavaScript коде используйте:
   ```javascript
   import { createClient } from '@supabase/supabase-js'
   
   const supabaseUrl = process.env.SUPABASE_URL
   const supabaseAnonKey = process.env.SUPABASE_ANON_KEY
   
   const supabase = createClient(supabaseUrl, supabaseAnonKey)
   ```

---

## Обновление контейнеров

### Автоматически
При каждом `git push` в ветку `main` GitHub Actions автоматически:
1. Соберет новый Docker образ
2. Остановит старые контейнеры
3. Запустит новые контейнеры с обновленным кодом

### Вручную
```bash
cd /opt/mediavelichie
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## Мониторинг и логи

### Просмотр логов
```bash
# Все сервисы
docker-compose -f docker-compose.prod.yml logs -f

# Только веб-сервер
docker-compose -f docker-compose.prod.yml logs -f web

# Только база данных
docker-compose -f docker-compose.prod.yml logs -f supabase
```

### Статус контейнеров
```bash
docker-compose -f docker-compose.prod.yml ps
```

### Использование ресурсов
```bash
docker stats
```

---

## Резервное копирование базы данных

### Создание бэкапа
```bash
docker-compose -f docker-compose.prod.yml exec supabase pg_dump -U postgres postgres > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление из бэкапа
```bash
cat backup_20231201_120000.sql | docker-compose -f docker-compose.prod.yml exec -T supabase psql -U postgres postgres
```

---

## Безопасность

1. **Измените пароли** в `.env` на продакшене
2. **Не коммитьте `.env`** в Git (уже добавлен в `.gitignore`)
3. **Используйте HTTPS** для продакшена (настройте SSL сертификат)
4. **Ограничьте доступ** к портам базы данных (5432) только локально
5. **Регулярно обновляйте** Docker образы для безопасности

---

## Troubleshooting

### Контейнеры не запускаются
```bash
docker-compose -f docker-compose.prod.yml logs
```

### Порт уже занят
Измените порты в `docker-compose.prod.yml`:
```yaml
ports:
  - "8080:80"  # Вместо 80:80
```

### Проблемы с правами доступа
```bash
sudo chown -R $USER:$USER /opt/mediavelichie
```

---

## Дополнительные настройки

### SSL/HTTPS через Let's Encrypt

Добавьте в `docker-compose.prod.yml`:
```yaml
web:
  volumes:
    - ./ssl:/etc/nginx/ssl:ro
```

И обновите `nginx.conf` для поддержки HTTPS.

### Кастомный домен

1. Настройте DNS записи на ваш сервер
2. Обновите `nginx.conf` с вашим доменом
3. Настройте SSL сертификат

---

## Полезные команды

```bash
# Перезапуск контейнеров
docker-compose -f docker-compose.prod.yml restart

# Остановка всех контейнеров
docker-compose -f docker-compose.prod.yml stop

# Удаление всех контейнеров и данных
docker-compose -f docker-compose.prod.yml down -v

# Просмотр использования диска
docker system df

# Очистка неиспользуемых образов
docker image prune -a
```
