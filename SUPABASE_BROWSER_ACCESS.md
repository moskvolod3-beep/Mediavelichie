# Доступ к Supabase через браузер

## Supabase Studio

Supabase Studio — веб-интерфейс для управления базой данных через браузер.

### Доступ

После запуска контейнеров Supabase Studio будет доступен по адресу:

```
http://localhost:3000
```

Или на удаленном сервере:

```
http://<IP-сервера>:3000
```

### Запуск

```bash
cd /opt/mediavelichia

# Запуск всех сервисов включая Studio
docker compose -f docker-compose.prod.yml up -d

# Или только Studio (если остальные уже запущены)
docker compose -f docker-compose.prod.yml up -d supabase-studio
```

### Проверка статуса

```bash
# Проверка что контейнер запущен
docker ps | grep supabase-studio

# Просмотр логов
docker logs mediavelichie-supabase-studio
```

### Подключение к базе данных через Studio

При первом запуске Studio может запросить данные для подключения:

- **Host**: `supabase` (имя сервиса в Docker сети) или `localhost`
- **Port**: `5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: значение из переменной `POSTGRES_PASSWORD` в `.env`

### Функции Studio

- Просмотр и редактирование таблиц
- Выполнение SQL запросов
- Управление схемой базы данных
- Просмотр данных
- Управление индексами и триггерами

## Альтернативные способы доступа

### 1. Прямое подключение к PostgreSQL

```bash
# Через Docker exec
docker exec -it mediavelichie-supabase-db psql -U postgres

# Или через psql клиент (если установлен)
psql -h localhost -p 5432 -U postgres -d postgres
```

### 2. pgAdmin (если установлен)

Подключение:
- Host: `localhost`
- Port: `5432`
- Database: `postgres`
- Username: `postgres`
- Password: из `.env` файла

### 3. DBeaver / DataGrip / другие SQL клиенты

Используйте те же параметры подключения что и для pgAdmin.

## Безопасность

⚠️ **Важно для продакшена:**

1. **Не открывайте порт 3000 публично** без защиты (firewall, VPN, reverse proxy с аутентификацией)
2. **Используйте сильные пароли** в `.env` файле
3. **Ограничьте доступ** к Studio только для администраторов
4. **Рассмотрите использование VPN** или SSH туннеля для доступа

### SSH туннель для безопасного доступа

```bash
# Создание SSH туннеля с локальной машины
ssh -L 3000:localhost:3000 user@your-server-ip

# После этого Studio будет доступен на http://localhost:3000
```

## Устранение проблем

### Studio не запускается

```bash
# Проверьте логи
docker logs mediavelichie-supabase-studio

# Проверьте что база данных запущена
docker ps | grep supabase-db

# Перезапустите Studio
docker compose -f docker-compose.prod.yml restart supabase-studio
```

### Не могу подключиться к базе данных через Studio

1. Проверьте что контейнер `supabase` запущен и здоров:
   ```bash
   docker ps | grep supabase-db
   docker logs mediavelichie-supabase-db
   ```

2. Проверьте пароль в `.env` файле

3. Убедитесь что оба контейнера в одной сети:
   ```bash
   docker network inspect mediavelichie-network
   ```

### Порт 3000 уже занят

Измените порт в `docker-compose.prod.yml`:

```yaml
ports:
  - "3001:3000"  # Внешний порт:внутренний порт
```

Тогда Studio будет доступен на `http://localhost:3001`
