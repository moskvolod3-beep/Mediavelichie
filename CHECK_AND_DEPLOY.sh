#!/bin/bash

# Скрипт для проверки и запуска деплоя на сервере
# Использование: ./CHECK_AND_DEPLOY.sh

set -e

PROJECT_DIR="/opt/mediavelichia"

echo "=========================================="
echo "Проверка и запуск деплоя"
echo "=========================================="
echo ""

# Переходим в директорию проекта
cd "$PROJECT_DIR" || {
    echo "Ошибка: директория $PROJECT_DIR не существует"
    exit 1
}

# Обновляем код из репозитория
echo "1. Обновление кода из репозитория..."
git pull origin main || {
    echo "Предупреждение: не удалось обновить код из репозитория"
    echo "Продолжаем с текущей версией..."
}

# Запускаем проверку готовности
echo ""
echo "2. Проверка готовности к деплою..."
if [ -f "check-deployment-ready.sh" ]; then
    chmod +x check-deployment-ready.sh
    ./check-deployment-ready.sh
    READY_EXIT_CODE=$?
else
    echo "Скрипт проверки не найден, выполняем базовую проверку..."
    READY_EXIT_CODE=0
fi

echo ""
echo "3. Проверка синтаксиса docker-compose..."
if docker compose -f docker-compose.prod.cloud.yml config > /dev/null 2>&1; then
    echo "✓ Синтаксис docker-compose.prod.cloud.yml корректен"
else
    echo "✗ Ошибка синтаксиса в docker-compose.prod.cloud.yml"
    echo "Проверьте файл или обновите из репозитория: git pull origin main"
    exit 1
fi

# Если проверка прошла успешно, предлагаем запустить
if [ $READY_EXIT_CODE -eq 0 ] || [ -z "$READY_EXIT_CODE" ]; then
    echo ""
    echo "=========================================="
    echo "Готово к запуску!"
    echo "=========================================="
    echo ""
    echo "Для запуска контейнеров выполните:"
    echo "  docker compose -f docker-compose.prod.cloud.yml up -d --build"
fi
