# Проверка состояния сервера

Инструкция по проверке текущего состояния сервера и установленных компонентов.

## Быстрая проверка

### На сервере

1. **Подключитесь к серверу по SSH:**
```bash
ssh root@your-server-ip
# или
ssh your-username@your-server-ip
```

2. **Скопируйте скрипт на сервер** (если проект еще не клонирован):
```bash
# Если проект уже клонирован
cd /opt/mediavelichia
chmod +x check-server-status.sh
./check-server-status.sh
```

Или скачайте скрипт напрямую:
```bash
curl -o check-server-status.sh https://raw.githubusercontent.com/moskvolod3-beep/Mediavelichie/main/check-server-status.sh
chmod +x check-server-status.sh
./check-server-status.sh
```

## Что проверяет скрипт

Скрипт `check-server-status.sh` проверяет:

1. **Информация о системе**
   - Версия ОС
   - Версия ядра
   - Архитектура
   - Время работы
   - Дата/время

2. **Ресурсы системы**
   - Использование памяти
   - Использование диска
   - Загрузка CPU

3. **Установленные пакеты**
   - Docker и Docker Compose
   - Git
   - curl, wget
   - nano
   - ufw (firewall)

4. **Статус Docker**
   - Статус сервиса Docker
   - Запущенные контейнеры
   - Docker образы
   - Docker volumes
   - Docker networks

5. **Порты**
   - Открытые порты (22, 80, 443, 5000, 5432)

6. **Директория проекта**
   - Существование `/opt/mediavelichia`
   - Наличие файла `.env`
   - Наличие Docker Compose файлов
   - Статус Git репозитория

7. **Контейнеры проекта**
   - Статус контейнеров (web, editor, supabase)
   - Health checks

8. **Сетевые подключения**
   - Docker сети

9. **Firewall**
   - Статус UFW

10. **Логи**
    - Последние логи системы
    - Логи Docker контейнеров

11. **Рекомендации**
    - Что нужно установить или настроить

## Ручная проверка (без скрипта)

Если вы не можете запустить скрипт, выполните команды вручную:

### Базовая информация о системе
```bash
# ОС
cat /etc/os-release

# Версия ядра
uname -r

# Ресурсы
free -h
df -h
uptime
```

### Проверка Docker
```bash
# Версия Docker
docker --version
docker compose version

# Статус сервиса
sudo systemctl status docker

# Контейнеры
docker ps -a

# Образы
docker images
```

### Проверка проекта
```bash
# Проверка директории
ls -la /opt/mediavelichia

# Проверка .env файла
ls -la /opt/mediavelichia/.env

# Проверка Git
cd /opt/mediavelichia
git status
git log -1
```

### Проверка портов
```bash
# Открытые порты
ss -tlnp | grep -E ':(22|80|443|5000|5432)'
# или
netstat -tlnp | grep -E ':(22|80|443|5000|5432)'
```

### Проверка контейнеров проекта
```bash
# Статус контейнеров
docker ps -a | grep mediavelichie

# Логи контейнеров
docker logs mediavelichie-web --tail 20
docker logs mediavelichie-editor --tail 20
docker logs mediavelichie-supabase-db --tail 20
```

## Интерпретация результатов

### ✅ Все хорошо
- Docker установлен и работает
- Контейнеры запущены и здоровы
- Порты открыты
- Файл `.env` существует

### ⚠️ Требуется внимание
- Docker не установлен → см. [DEPLOY.md](./DEPLOY.md) раздел "Подготовка сервера"
- Контейнеры не запущены → проверьте логи и запустите `docker compose up -d`
- Файл `.env` отсутствует → создайте на основе `.env.example`
- Порты закрыты → проверьте firewall и настройки сети

### ❌ Критические проблемы
- Docker не работает → переустановите Docker
- Контейнеры падают → проверьте логи и конфигурацию
- Недостаточно места на диске → освободите место

## Следующие шаги

После проверки состояния сервера:

1. Если Docker не установлен → следуйте инструкциям в [DEPLOY.md](./DEPLOY.md)
2. Если проект не развернут → выполните деплой согласно [DEPLOY.md](./DEPLOY.md)
3. Если есть проблемы → см. раздел "Устранение неполадок" в [DEPLOY.md](./DEPLOY.md)

## Автоматическая проверка

Вы можете добавить проверку в cron для регулярного мониторинга:

```bash
# Добавить в crontab (каждый день в 9:00)
0 9 * * * /opt/mediavelichia/check-server-status.sh >> /var/log/server-check.log 2>&1
```

Или создать простой мониторинг:

```bash
# Проверка статуса контейнеров каждые 5 минут
*/5 * * * * docker ps | grep -q mediavelichie-web || echo "Container down" | mail -s "Alert" admin@example.com
```
