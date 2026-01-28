# Быстрая проверка готовности к деплою


## Команды для выполнения на сервере

Выполните эти команды на сервере для проверки готовности:

### Вариант 1: Автоматическая проверка (рекомендуется)

```bash
cd /opt/mediavelichia

# Обновляем код
git pull origin main

# Скачиваем и запускаем скрипт проверки
curl -o check-deployment-ready.sh https://raw.githubusercontent.com/moskvolod3-beep/Mediavelichie/main/check-deployment-ready.sh
chmod +x check-deployment-ready.sh
./check-deployment-ready.sh
```

### Вариант 2: Ручная проверка

```bash
cd /opt/mediavelichia

# 1. Проверка Docker
docker --version
docker compose version
docker ps

# 2. Проверка Git
git status
git branch

# 3. Проверка файлов
ls -la docker-compose.prod.cloud.yml Dockerfile .env

# 4. Проверка синтаксиса YAML
docker compose -f docker-compose.prod.cloud.yml config

# 5. Проверка .env (без показа значений)
grep -v "^#" .env | grep "=" | cut -d'=' -f1

# 6. Проверка портов
ss -tlnp | grep -E ':(80|443|5000)' || echo "Порты свободны"

# 7. Проверка места на диске
df -h /
```

### Вариант 3: Полная проверка и запуск

```bash
cd /opt/mediavelichia
git pull origin main
chmod +x check-deployment-ready.sh CHECK_AND_DEPLOY.sh
./CHECK_AND_DEPLOY.sh
```

## Что проверяется

1. ✅ Docker установлен и работает
2. ✅ Docker Compose установлен
3. ✅ Git репозиторий инициализирован
4. ✅ Файлы конфигурации существуют
5. ✅ Синтаксис YAML корректен
6. ✅ Файл .env настроен
7. ✅ Порты свободны
8. ✅ Достаточно места на диске
9. ✅ Достаточно памяти

## После проверки

Если все проверки пройдены, запустите:

```bash
docker compose -f docker-compose.prod.cloud.yml up -d --build
```
