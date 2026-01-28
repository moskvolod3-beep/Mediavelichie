# Скрипт перезапуска и проверки Docker контейнеров

## Описание

Скрипт `restart-and-check.sh` автоматически:
1. Останавливает все Docker контейнеры
2. Запускает их заново
3. Проверяет статус контейнеров
4. Проверяет доступность всех сервисов по IP адресу

## Использование

### Базовое использование (автоматическое определение IP)

```bash
cd /opt/mediavelichia
chmod +x restart-and-check.sh
./restart-and-check.sh
```

Скрипт автоматически определит IP адрес сервера и проверит доступность всех сервисов.

### С указанием IP адреса

```bash
./restart-and-check.sh 194.58.88.127
```

## Что проверяется

Скрипт проверяет доступность следующих сервисов:

1. **Web (HTTP)** - порт 80
   - URL: `http://SERVER_IP`
   - Проверка HTTP ответа

2. **Supabase PostgreSQL** - порт 5432
   - Connection: `SERVER_IP:5432`
   - Проверка доступности порта

3. **Supabase Studio** - порт 3000
   - URL: `http://SERVER_IP:3000`
   - Проверка HTTP ответа

4. **Editor (Flask)** - порт 5000
   - URL: `http://SERVER_IP:5000`
   - Проверка HTTP ответа

## Вывод скрипта

Скрипт выводит:

1. **Статус контейнеров** - список всех контейнеров и их состояние
2. **Результаты проверки** - для каждого сервиса:
   - ✓ OK - сервис доступен
   - ✗ FAILED - сервис недоступен
   - ⚠ WARNING - сервис может еще запускаться

3. **Итоговый отчет** - сводка по всем сервисам с URL для доступа

4. **Логи** - если есть проблемы, показываются последние строки логов

## Пример вывода

```
==========================================
Docker Restart and Health Check
==========================================

Server IP: 194.58.88.127
Project directory: /opt/mediavelichia

Step 1: Stopping containers...
Step 2: Starting containers...
Step 3: Waiting for containers to start...

Step 4: Container Status
==========================================
NAME                          STATUS
mediavelichie-web             Up (healthy)
mediavelichie-supabase-db     Up (healthy)
mediavelichie-supabase-studio Up
mediavelichie-editor          Up

Step 5: Service Availability Check
==========================================

Checking Web (HTTP port 80)... ✓ OK
  URL: http://194.58.88.127
Checking Supabase PostgreSQL (port 5432)... ✓ OK
  Connection: 194.58.88.127:5432
Checking Supabase Studio (port 3000)... ✓ OK
  URL: http://194.58.88.127:3000
Checking Editor (port 5000)... ✓ OK
  URL: http://194.58.88.127:5000

==========================================
Health Check Summary
==========================================

Web (HTTP):        ✓ Available - http://194.58.88.127
Supabase (DB):     ✓ Available - 194.58.88.127:5432
Supabase Studio:   ✓ Available - http://194.58.88.127:3000
Editor:            ✓ Available - http://194.58.88.127:5000

==========================================
✓ Core services are running!

Access URLs:
  Website:        http://194.58.88.127
  Supabase DB:    194.58.88.127:5432
  Supabase Studio: http://194.58.88.127:3000
  Editor:         http://194.58.88.127:5000

Restart completed successfully!
```

## Устранение проблем

### Сервис не запускается

Если сервис показывает ✗ FAILED:

1. Проверьте логи контейнера:
   ```bash
   docker compose -f docker-compose.prod.yml logs -f SERVICE_NAME
   ```

2. Проверьте статус контейнера:
   ```bash
   docker compose -f docker-compose.prod.yml ps
   ```

3. Перезапустите конкретный сервис:
   ```bash
   docker compose -f docker-compose.prod.yml restart SERVICE_NAME
   ```

### Порт недоступен

Если порт показывает ✗ FAILED:

1. Проверьте, что порт открыт в firewall:
   ```bash
   ufw status
   ```

2. Проверьте, что контейнер слушает на правильном порту:
   ```bash
   docker port CONTAINER_NAME
   ```

3. Проверьте, не занят ли порт другим процессом:
   ```bash
   netstat -tulpn | grep PORT_NUMBER
   ```

### Сервис запускается медленно

Если сервис показывает ⚠ WARNING, подождите 1-2 минуты и проверьте снова:

```bash
# Проверка конкретного сервиса
curl http://SERVER_IP:PORT

# Или проверка через Docker
docker compose -f docker-compose.prod.yml ps
```

## Интеграция с другими скриптами

Скрипт можно использовать в комбинации с другими:

```bash
# После импорта образов
./rebuild-images-on-server.sh
./restart-and-check.sh

# После обновления кода
git pull origin main
./restart-and-check.sh
```

## Автоматизация

Для автоматической проверки можно добавить в cron:

```bash
# Проверка каждый час
0 * * * * cd /opt/mediavelichia && ./restart-and-check.sh > /var/log/docker-check.log 2>&1
```

## Требования

- Docker и Docker Compose установлены
- Доступ к `/opt/mediavelichia/docker-compose.prod.yml`
- Права на выполнение Docker команд
- Утилиты для проверки портов: `nc` (netcat), `curl`, или `wget` (хотя бы одна)

## Безопасность

⚠️ **Важно:**

- Скрипт проверяет доступность сервисов по IP адресу
- Убедитесь, что firewall настроен правильно
- Не используйте скрипт на продакшене без предварительного тестирования
- Проверьте, что порты не открыты публично без необходимости
