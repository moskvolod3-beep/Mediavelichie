# Руководство по подключению Supabase Studio к PostgreSQL

## Текущая ситуация

✅ **Что работает:**
- PostgreSQL запущен и работает
- Supabase Studio запущен и доступен на порту 3000
- Пароли совпадают
- Контейнеры в одной сети

⚠️ **Проблема:**
Supabase Studio в standalone режиме **не подключается автоматически** к базе данных. Нужно подключиться вручную через веб-интерфейс.

## Решение: Подключение через веб-интерфейс

### Шаг 1: Откройте Supabase Studio

Откройте в браузере:
```
http://194.58.88.127:3000
```

### Шаг 2: Введите данные подключения

При первом открытии Studio покажет форму для подключения к базе данных (как на скриншоте). Заполните форму следующими данными:

**Для подключения через браузер (рекомендуется):**
- **Host:** `194.58.88.127` (IP вашего сервера)
- **Port:** `5432`
- **Database:** `postgres`
- **User:** `postgres`
- **Password:** `yNtGMC35GnqF8Od9PMZSDrKRR0I6jFJ2` (из вашего `.env` файла)

**Важно:** 
- Если форма показывает `127.0.0.1` как пример, замените на `194.58.88.127` (IP вашего сервера)
- Пароль не отображается в интерфейсе по соображениям безопасности - введите его вручную
- Если подключение не работает с внешним IP, попробуйте `supabase` (имя Docker сервиса) - но это работает только если Studio может обращаться к Docker сети

### Шаг 3: Сохраните подключение

После успешного подключения Studio сохранит эти данные и будет использовать их автоматически при следующих запусках.

## Альтернативные решения

### Вариант 1: Использовать pgAdmin (рекомендуется для продакшена)

Если Studio не работает стабильно, используйте pgAdmin:

```yaml
# Добавьте в docker-compose.prod.yml:
pgadmin:
  image: dpage/pgadmin4:latest
  container_name: mediavelichie-pgadmin
  ports:
    - "5050:80"
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@example.com
    PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-change-me}
    PGADMIN_CONFIG_SERVER_MODE: 'False'
  volumes:
    - pgadmin-data:/var/lib/pgadmin
  networks:
    - mediavelichie-network
```

Подключение в pgAdmin:
- Host: `supabase` (изнутри Docker) или `194.58.88.127` (извне)
- Port: `5432`
- Database: `postgres`
- Username: `postgres`
- Password: из `.env`

### Вариант 2: Использовать облачный Supabase Studio

Для продакшена рекомендуется использовать облачный Supabase:
1. Создайте проект на https://supabase.com
2. Подключите вашу БД через connection pooling
3. Используйте облачный Studio для управления

### Вариант 3: Использовать DBeaver или другой SQL клиент

Подключитесь напрямую:
- Host: `194.58.88.127`
- Port: `5432`
- Database: `postgres`
- Username: `postgres`
- Password: из `.env`

## Проверка подключения

После подключения через Studio проверьте:

```bash
# Проверьте что Studio может видеть таблицы
# (откройте Studio в браузере и проверьте раздел "Table Editor")

# Или проверьте через psql напрямую:
docker exec -it mediavelichie-supabase-db psql -U postgres -c "\dt"
```

## Устранение проблем

### Studio не открывается

```bash
# Проверьте статус контейнера
docker ps | grep supabase-studio

# Проверьте логи
docker logs mediavelichie-supabase-studio --tail 50

# Перезапустите
docker compose -f docker-compose.prod.yml restart supabase-studio
```

### Не могу подключиться к БД через Studio

1. **Проверьте пароль:**
   ```bash
   docker exec mediavelichie-supabase-db env | grep POSTGRES_PASSWORD
   ```

2. **Проверьте доступность порта:**
   ```bash
   # С сервера
   nc -zv localhost 5432
   
   # Или из контейнера Studio
   docker exec mediavelichie-supabase-studio sh -c "timeout 2 sh -c '</dev/tcp/supabase/5432' 2>&1" || echo "Port not accessible"
   ```

3. **Проверьте сеть:**
   ```bash
   docker network inspect mediavelichie-network | grep -A 5 "Containers"
   ```

### Studio показывает ошибку подключения

Если Studio показывает ошибку при попытке подключения:

1. Убедитесь что используете правильный Host:
   - Из браузера (вне Docker): `194.58.88.127`
   - Изнутри Docker сети: `supabase`

2. Проверьте что PostgreSQL принимает подключения:
   ```bash
   docker exec mediavelichie-supabase-db psql -U postgres -c "SELECT version();"
   ```

3. Проверьте firewall на сервере:
   ```bash
   ufw status
   # Если порт 5432 закрыт, откройте его:
   # ufw allow 5432/tcp
   ```

## Рекомендации для продакшена

1. **Не открывайте порт 3000 публично** - используйте SSH туннель:
   ```bash
   ssh -L 3000:localhost:3000 root@194.58.88.127
   # Затем откройте http://localhost:3000
   ```

2. **Используйте сильные пароли** в `.env` файле

3. **Рассмотрите использование облачного Supabase** для продакшена

4. **Используйте pgAdmin** вместо Studio для более стабильной работы
