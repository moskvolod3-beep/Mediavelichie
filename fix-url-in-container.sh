#!/bin/bash

# Скрипт для исправления URL прямо в запущенном контейнере
# Использование: ./fix-url-in-container.sh [SUPABASE_URL]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CONTAINER_NAME="mediavelichie-web"

# Определяем Supabase URL
if [ -n "$1" ]; then
    SUPABASE_URL="$1"
else
    # Пытаемся получить из .env файла
    if [ -f ".env" ]; then
        SUPABASE_URL=$(grep "^SUPABASE_URL=" .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
    fi
    
    if [ -z "$SUPABASE_URL" ]; then
        echo -e "${RED}Error: SUPABASE_URL not provided${NC}"
        echo ""
        echo "Usage: ./fix-url-in-container.sh [SUPABASE_URL]"
        echo ""
        echo "Example:"
        echo "  ./fix-url-in-container.sh https://your-project-id.supabase.co"
        exit 1
    fi
fi

# Убираем завершающий слеш
SUPABASE_URL=$(echo "$SUPABASE_URL" | sed 's:/*$::')

echo "=========================================="
echo -e "${CYAN}Fix Supabase URL in Container${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Container:${NC} $CONTAINER_NAME"
echo -e "${BLUE}Supabase URL:${NC} $SUPABASE_URL"
echo ""

# Проверяем что контейнер существует и запущен
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: Container $CONTAINER_NAME is not running${NC}"
    echo "Start it with: docker compose -f docker-compose.prod.yml up -d web"
    exit 1
fi

echo -e "${BLUE}Replacing URLs in container files...${NC}"
echo ""

# Заменяем URL в config.js
docker exec "$CONTAINER_NAME" sh -c "
    # Заменяем в config.js (все варианты включая плейсхолдеры)
    sed -i \"s|url: '.*'|url: '${SUPABASE_URL}'|g\" /usr/share/nginx/html/supabase/config.js && \
    sed -i \"s|url: \\\".*\\\"|url: \\\"${SUPABASE_URL}\\\"|g\" /usr/share/nginx/html/supabase/config.js && \
    sed -i \"s|http://194\.58\.88\.127:5432|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js && \
    sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js && \
    sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js && \
    sed -i \"s|https://your-project-id\.supabase\.co|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js && \
    # Заменяем в HTML файлах
    find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|http://194\.58\.88\.127:5432|${SUPABASE_URL}|g\" {} \; && \
    find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" {} \; && \
    find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" {} \; && \
    find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|https://your-project-id\.supabase\.co|${SUPABASE_URL}|g\" {} \; && \
    # Заменяем в JS файлах
    find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|http://194\.58\.88\.127:5432|${SUPABASE_URL}|g\" {} \; && \
    find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" {} \; && \
    find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" {} \; && \
    find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|https://your-project-id\.supabase\.co|${SUPABASE_URL}|g\" {} \;
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ URLs replaced successfully${NC}"
else
    echo -e "${RED}✗ Error replacing URLs${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Verifying changes...${NC}"
echo ""

# Проверяем результат
NEW_URL=$(docker exec "$CONTAINER_NAME" cat /usr/share/nginx/html/supabase/config.js | grep "url:" | head -1 | sed "s/.*url: ['\"]\(.*\)['\"].*/\1/")

echo -e "${BLUE}Current URL in config.js:${NC}"
docker exec "$CONTAINER_NAME" cat /usr/share/nginx/html/supabase/config.js | grep "url:" | head -1

echo ""
echo "=========================================="
if echo "$NEW_URL" | grep -q "$SUPABASE_URL"; then
    echo -e "${GREEN}✓ URL updated successfully!${NC}"
else
    echo -e "${YELLOW}⚠ URL may not have updated correctly${NC}"
    echo "Expected: $SUPABASE_URL"
    echo "Found: $NEW_URL"
fi
echo "=========================================="
echo ""
echo -e "${YELLOW}Note:${NC} These changes are temporary and will be lost when container is rebuilt."
echo ""
echo -e "${BLUE}To make changes permanent:${NC}"
echo "  1. Update SUPABASE_URL in .env file"
echo "  2. Rebuild container: docker compose -f docker-compose.prod.yml build web"
echo "  3. Restart: docker compose -f docker-compose.prod.yml up -d web"
echo ""
