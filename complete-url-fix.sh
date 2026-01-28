#!/bin/bash

# Полное исправление URL: исправляет .env, пересобирает контейнер и проверяет результат
# Использование: ./complete-url-fix.sh [SUPABASE_URL]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ENV_FILE=".env"
CONTAINER_NAME="mediavelichie-web"
COMPOSE_FILE="docker-compose.prod.yml"

echo "=========================================="
echo -e "${CYAN}Complete URL Fix${NC}"
echo "=========================================="
echo ""

# Определяем Supabase URL
if [ -n "$1" ]; then
    SUPABASE_URL="$1"
else
    # Пытаемся получить из .env файла
    if [ -f "$ENV_FILE" ]; then
        SUPABASE_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
    fi
    
    if [ -z "$SUPABASE_URL" ] || echo "$SUPABASE_URL" | grep -q "your-project-id"; then
        echo -e "${RED}Error: SUPABASE_URL not set or contains placeholder${NC}"
        echo ""
        echo "Usage: ./complete-url-fix.sh [SUPABASE_URL]"
        echo ""
        echo "Example:"
        echo "  ./complete-url-fix.sh https://xxxxxxxxxxxxx.supabase.co"
        exit 1
    fi
fi

# Убираем завершающий слеш
SUPABASE_URL=$(echo "$SUPABASE_URL" | sed 's:/*$::')

echo -e "${BLUE}Supabase URL:${NC} $SUPABASE_URL"
echo ""

# Проверяем что URL не является плейсхолдером
if echo "$SUPABASE_URL" | grep -q "your-project-id\|placeholder\|example"; then
    echo -e "${RED}Error: URL contains placeholder. Please provide real Supabase URL${NC}"
    exit 1
fi

# Шаг 1: Исправляем .env файл
echo -e "${BLUE}Step 1: Updating .env file...${NC}"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Создаем резервную копию
cp "$ENV_FILE" "$ENV_FILE.bak"
echo -e "${GREEN}✓ Backup created: ${ENV_FILE}.bak${NC}"

# Заменяем или добавляем SUPABASE_URL
if grep -q "^SUPABASE_URL=" "$ENV_FILE"; then
    sed -i "s|^SUPABASE_URL=.*|SUPABASE_URL=${SUPABASE_URL}|g" "$ENV_FILE"
    echo -e "${GREEN}✓ Updated SUPABASE_URL in .env${NC}"
else
    echo "SUPABASE_URL=${SUPABASE_URL}" >> "$ENV_FILE"
    echo -e "${GREEN}✓ Added SUPABASE_URL to .env${NC}"
fi

# Проверяем результат
CURRENT_ENV_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
if [ "$CURRENT_ENV_URL" != "$SUPABASE_URL" ]; then
    echo -e "${RED}Error: Failed to update .env file${NC}"
    exit 1
fi

echo ""

# Шаг 2: Получаем последние изменения
echo -e "${BLUE}Step 2: Getting latest code...${NC}"
git pull origin main || echo -e "${YELLOW}Warning: git pull failed, continuing...${NC}"
echo ""

# Шаг 3: Исправляем URL в запущенном контейнере (временное решение)
echo -e "${BLUE}Step 3: Fixing URL in running container (temporary)...${NC}"
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker exec "$CONTAINER_NAME" sh -c "
        # Заменяем в config.js
        sed -i \"s|url: '.*'|url: '${SUPABASE_URL}'|g\" /usr/share/nginx/html/supabase/config.js && \
        sed -i \"s|url: \\\".*\\\"|url: \\\"${SUPABASE_URL}\\\"|g\" /usr/share/nginx/html/supabase/config.js && \
        sed -i \"s|http://.*:5432|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js && \
        sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js && \
        sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js && \
        # Заменяем во всех HTML и JS файлах
        find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|https://your-project-id\.supabase\.co|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|https://your-project-id\.supabase\.co|${SUPABASE_URL}|g\" {} \;
    " 2>/dev/null && echo -e "${GREEN}✓ URLs replaced in container${NC}" || echo -e "${YELLOW}⚠ Could not replace URLs in container (may not be running)${NC}"
else
    echo -e "${YELLOW}⚠ Container not running, skipping temporary fix${NC}"
fi
echo ""

# Шаг 4: Пересобираем контейнер
echo -e "${BLUE}Step 4: Rebuilding container with correct URL...${NC}"
echo "This may take a few minutes..."
docker compose -f "$COMPOSE_FILE" build --no-cache web

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Container rebuilt successfully${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

# Шаг 5: Перезапускаем контейнер
echo -e "${BLUE}Step 5: Restarting container...${NC}"
docker compose -f "$COMPOSE_FILE" up -d web
echo ""

# Шаг 6: Проверяем результат
echo -e "${BLUE}Step 6: Verifying URL replacement...${NC}"
sleep 2

CONFIG_URL=$(docker exec "$CONTAINER_NAME" cat /usr/share/nginx/html/supabase/config.js 2>/dev/null | grep "url:" | head -1 | sed "s/.*url: ['\"]\(.*\)['\"].*/\1/" || echo "")

echo ""
echo "=========================================="
echo -e "${CYAN}Verification Results${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}URL in .env:${NC} $CURRENT_ENV_URL"
echo -e "${BLUE}URL in container config.js:${NC} $CONFIG_URL"
echo ""

if echo "$CONFIG_URL" | grep -q "$SUPABASE_URL"; then
    echo -e "${GREEN}✓ URL correctly replaced!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Clear browser cache (Ctrl+Shift+Delete)"
    echo "  2. Open website: http://medvel.ru"
    echo "  3. Check browser console (F12) for errors"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠ URL may not have been replaced correctly${NC}"
    echo ""
    echo "Checking for remaining localhost URLs..."
    LOCALHOST_COUNT=$(docker exec "$CONTAINER_NAME" sh -c "grep -r '127.0.0.1:54321\|localhost:54321\|your-project-id' /usr/share/nginx/html 2>/dev/null | wc -l" || echo "0")
    if [ "$LOCALHOST_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}Found $LOCALHOST_COUNT occurrences of localhost URLs${NC}"
        echo "Run fix-url-in-container.sh to fix them manually"
    fi
    echo ""
    exit 1
fi
