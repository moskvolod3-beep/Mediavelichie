#!/bin/bash

# Скрипт для исправления проблем перед деплоем
# Использование: ./fix-deployment-issues.sh

set -e

PROJECT_DIR="/opt/mediavelichia"
ENV_FILE="$PROJECT_DIR/.env"

echo "=========================================="
echo "Исправление проблем перед деплоем"
echo "=========================================="
echo ""

# Переходим в директорию проекта
cd "$PROJECT_DIR" || {
    echo "Ошибка: директория $PROJECT_DIR не существует"
    exit 1
}

# Шаг 1: Обновление кода
echo "1. Обновление кода из репозитория..."
if git pull origin main; then
    echo "✓ Код обновлен"
else
    echo "⚠ Предупреждение: не удалось обновить код из репозитория"
    echo "Продолжаем с текущей версией..."
fi

# Шаг 2: Проверка синтаксиса YAML
echo ""
echo "2. Проверка синтаксиса docker-compose..."
if docker compose -f docker-compose.prod.cloud.yml config > /dev/null 2>&1; then
    echo "✓ Синтаксис docker-compose.prod.cloud.yml корректен"
else
    echo "✗ Ошибка синтаксиса в docker-compose.prod.cloud.yml"
    echo ""
    echo "Попытка автоматического исправления..."
    
    # Исправление YAML синтаксиса
    if grep -q 'CMD.*wget.*health.*exit 0' docker-compose.prod.cloud.yml 2>/dev/null; then
        sed -i 's|test: \["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5000/health"\] || exit 0|test: ["CMD-SHELL", "wget --quiet --tries=1 --spider http://localhost:5000/health || exit 0"]|g' docker-compose.prod.cloud.yml
        
        if docker compose -f docker-compose.prod.cloud.yml config > /dev/null 2>&1; then
            echo "✓ YAML синтаксис исправлен автоматически"
        else
            echo "✗ Не удалось исправить автоматически. Обновите код: git pull origin main"
            exit 1
        fi
    else
        echo "✗ Не удалось найти проблемную строку. Обновите код: git pull origin main"
        exit 1
    fi
fi

# Шаг 3: Проверка .env файла
echo ""
echo "3. Проверка переменных окружения..."
if [ ! -f "$ENV_FILE" ]; then
    echo "✗ Файл .env не найден"
    echo ""
    echo "Создайте файл .env:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    echo ""
    echo "Заполните обязательные переменные:"
    echo "  - SUPABASE_URL"
    echo "  - SUPABASE_ANON_KEY"
    echo "  - SUPABASE_SERVICE_KEY (опционально, но рекомендуется)"
    exit 1
fi

# Проверка обязательных переменных
source "$ENV_FILE" 2>/dev/null || true

MISSING_VARS=()

if [ -z "$SUPABASE_URL" ] || [ "$SUPABASE_URL" = "https://your-project.supabase.co" ]; then
    MISSING_VARS+=("SUPABASE_URL")
fi

if [ -z "$SUPABASE_ANON_KEY" ] || [ "$SUPABASE_ANON_KEY" = "your-anon-public-key-here" ]; then
    MISSING_VARS+=("SUPABASE_ANON_KEY")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "✗ Не настроены обязательные переменные:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Отредактируйте файл .env:"
    echo "  nano $ENV_FILE"
    echo ""
    echo "См. инструкции в FIX_ALL_ISSUES.md"
    exit 1
fi

echo "✓ Обязательные переменные настроены"

if [ -z "$SUPABASE_SERVICE_KEY" ] || [ "$SUPABASE_SERVICE_KEY" = "your-service-role-key-here" ]; then
    echo "⚠ SUPABASE_SERVICE_KEY не настроен (нужен для backend)"
    echo "  Рекомендуется настроить для полной функциональности"
fi

# Итоги
echo ""
echo "=========================================="
echo "Проверка завершена"
echo "=========================================="
echo ""
echo "✓ YAML синтаксис корректен"
echo "✓ Переменные окружения настроены"
echo ""
echo "Готово к запуску!"
echo ""
echo "Для запуска контейнеров выполните:"
echo "  docker compose -f docker-compose.prod.cloud.yml up -d --build"
echo ""
