#!/bin/bash

# Скрипт проверки статуса Supabase
# Использование: ./check-supabase-status.sh

echo "=========================================="
echo "Проверка статуса Supabase"
echo "=========================================="
echo ""

PROJECT_DIR="/opt/mediavelichia"
ENV_FILE="$PROJECT_DIR/.env"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Проверка локального контейнера Supabase
echo "1. Проверка локального контейнера Supabase"
SUPABASE_CONTAINER=$(docker ps -a --format '{{.Names}}' | grep -E 'supabase|mediavelichie-supabase' || true)

if [ -n "$SUPABASE_CONTAINER" ]; then
    echo -e "${BLUE}Найден контейнер Supabase: $SUPABASE_CONTAINER${NC}"
    
    # Проверка статуса
    CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$SUPABASE_CONTAINER" 2>/dev/null || echo "unknown")
    
    if [ "$CONTAINER_STATUS" = "running" ]; then
        echo -e "${GREEN}✓ Локальный Supabase запущен${NC}"
        
        # Проверка порта
        if docker port "$SUPABASE_CONTAINER" 2>/dev/null | grep -q "5432"; then
            PORT=$(docker port "$SUPABASE_CONTAINER" | grep "5432" | cut -d: -f2)
            echo -e "${GREEN}  Порт PostgreSQL: $PORT${NC}"
        fi
        
        # Проверка подключения
        if command -v pg_isready &> /dev/null || docker exec "$SUPABASE_CONTAINER" pg_isready -U postgres &> /dev/null 2>&1; then
            echo -e "${GREEN}  База данных доступна${NC}"
        else
            echo -e "${YELLOW}  ⚠ Не удалось проверить доступность БД${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Локальный Supabase не запущен (статус: $CONTAINER_STATUS)${NC}"
        echo "  Для запуска: docker start $SUPABASE_CONTAINER"
    fi
else
    echo -e "${BLUE}Локальный контейнер Supabase не найден${NC}"
    echo "  Это означает, что используется облачный Supabase"
fi

# 2. Проверка конфигурации в .env
echo ""
echo "2. Проверка конфигурации Supabase в .env"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ Файл .env не найден${NC}"
    exit 1
fi

# Загружаем переменные окружения
source "$ENV_FILE" 2>/dev/null || true

if [ -n "$SUPABASE_URL" ]; then
    echo -e "${GREEN}✓ SUPABASE_URL настроен${NC}"
    echo "  URL: $SUPABASE_URL"
    
    # Определяем тип Supabase
    if echo "$SUPABASE_URL" | grep -qE '^https?://.*\.supabase\.co'; then
        echo -e "${BLUE}  Тип: Облачный Supabase${NC}"
        SUPABASE_TYPE="cloud"
    elif echo "$SUPABASE_URL" | grep -qE '^https?://(localhost|127\.0\.0\.1|supabase)'; then
        echo -e "${BLUE}  Тип: Локальный Supabase${NC}"
        SUPABASE_TYPE="local"
    else
        echo -e "${YELLOW}  Тип: Неизвестный${NC}"
        SUPABASE_TYPE="unknown"
    fi
else
    echo -e "${RED}✗ SUPABASE_URL не настроен${NC}"
    SUPABASE_TYPE="none"
fi

if [ -n "$SUPABASE_ANON_KEY" ] && [ "$SUPABASE_ANON_KEY" != "your-anon-public-key-here" ]; then
    echo -e "${GREEN}✓ SUPABASE_ANON_KEY настроен${NC}"
    echo "  Key: ${SUPABASE_ANON_KEY:0:30}..."
else
    echo -e "${RED}✗ SUPABASE_ANON_KEY не настроен или содержит placeholder${NC}"
fi

if [ -n "$SUPABASE_SERVICE_KEY" ] && [ "$SUPABASE_SERVICE_KEY" != "your-service-role-key-here" ]; then
    echo -e "${GREEN}✓ SUPABASE_SERVICE_KEY настроен${NC}"
    echo "  Key: ${SUPABASE_SERVICE_KEY:0:30}..."
else
    echo -e "${YELLOW}⚠ SUPABASE_SERVICE_KEY не настроен${NC}"
fi

# 3. Проверка доступности Supabase
echo ""
echo "3. Проверка доступности Supabase"

if [ "$SUPABASE_TYPE" = "cloud" ] && [ -n "$SUPABASE_URL" ]; then
    echo "Проверка подключения к облачному Supabase..."
    
    # Простая проверка доступности URL
    if command -v curl &> /dev/null; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL" 2>/dev/null || echo "000")
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
            echo -e "${GREEN}✓ Облачный Supabase доступен (HTTP $HTTP_CODE)${NC}"
        else
            echo -e "${YELLOW}⚠ Не удалось подключиться к облачному Supabase (HTTP $HTTP_CODE)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ curl не установлен, пропускаем проверку доступности${NC}"
    fi
elif [ "$SUPABASE_TYPE" = "local" ]; then
    if [ -n "$SUPABASE_CONTAINER" ] && [ "$CONTAINER_STATUS" = "running" ]; then
        echo -e "${GREEN}✓ Локальный Supabase доступен${NC}"
    else
        echo -e "${RED}✗ Локальный Supabase не запущен${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Не удалось определить тип Supabase для проверки${NC}"
fi

# 4. Проверка используемого docker-compose файла
echo ""
echo "4. Проверка конфигурации Docker Compose"

cd "$PROJECT_DIR" 2>/dev/null || exit 1

if [ -f "docker-compose.prod.cloud.yml" ]; then
    echo -e "${BLUE}Найден: docker-compose.prod.cloud.yml${NC}"
    echo "  Используется для облачного Supabase"
fi

if [ -f "docker-compose.prod.yml" ]; then
    echo -e "${BLUE}Найден: docker-compose.prod.yml${NC}"
    echo "  Используется для локального Supabase"
fi

# Итоги
echo ""
echo "=========================================="
echo "Итоги проверки"
echo "=========================================="

if [ "$SUPABASE_TYPE" = "cloud" ]; then
    echo -e "${GREEN}✓ Используется облачный Supabase${NC}"
    echo ""
    echo "Облачный Supabase не требует локального запуска."
    echo "Убедитесь, что:"
    echo "  1. SUPABASE_URL указывает на ваш проект Supabase"
    echo "  2. SUPABASE_ANON_KEY настроен правильно"
    echo "  3. Проект создан на https://supabase.com"
elif [ "$SUPABASE_TYPE" = "local" ]; then
    if [ -n "$SUPABASE_CONTAINER" ] && [ "$CONTAINER_STATUS" = "running" ]; then
        echo -e "${GREEN}✓ Локальный Supabase запущен и работает${NC}"
    else
        echo -e "${YELLOW}⚠ Локальный Supabase настроен, но не запущен${NC}"
        echo ""
        echo "Для запуска локального Supabase:"
        echo "  docker compose -f docker-compose.prod.yml up -d supabase"
    fi
else
    echo -e "${RED}✗ Не удалось определить статус Supabase${NC}"
    echo ""
    echo "Проверьте настройки в файле .env"
fi

echo ""
