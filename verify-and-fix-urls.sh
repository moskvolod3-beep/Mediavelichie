#!/bin/bash

# Скрипт для проверки и исправления локальных URL в контейнере
# Использование: ./verify-and-fix-urls.sh [SUPABASE_URL]

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
        echo "Usage: ./verify-and-fix-urls.sh [SUPABASE_URL]"
        exit 1
    fi
fi

SUPABASE_URL=$(echo "$SUPABASE_URL" | sed 's:/*$::')

echo "=========================================="
echo -e "${CYAN}Verify and Fix URLs in Container${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Container:${NC} $CONTAINER_NAME"
echo -e "${BLUE}Supabase URL:${NC} $SUPABASE_URL"
echo ""

# Проверяем что контейнер существует
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: Container $CONTAINER_NAME not found${NC}"
    exit 1
fi

# Проверяем что контейнер запущен
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Warning: Container is not running. Starting it...${NC}"
    docker start "$CONTAINER_NAME"
    sleep 2
fi

echo -e "${BLUE}Checking for localhost URLs in container...${NC}"
echo ""

# Проверяем наличие localhost URL в файлах контейнера
LOCALHOST_COUNT=$(docker exec "$CONTAINER_NAME" sh -c "grep -r '127.0.0.1:54321\|localhost:54321' /usr/share/nginx/html 2>/dev/null | wc -l" || echo "0")

if [ "$LOCALHOST_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Found $LOCALHOST_COUNT occurrences of localhost URLs${NC}"
    echo ""
    echo -e "${BLUE}Sample occurrences:${NC}"
    docker exec "$CONTAINER_NAME" sh -c "grep -r '127.0.0.1:54321\|localhost:54321' /usr/share/nginx/html 2>/dev/null | head -5" || true
    echo ""
    echo -e "${YELLOW}Fixing URLs in container...${NC}"
    
    # Заменяем URL в контейнере
    docker exec "$CONTAINER_NAME" sh -c "
        find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.html' -type f -exec sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" {} \; && \
        find /usr/share/nginx/html -name '*.js' -type f -exec sed -i \"s|http://localhost:54321|${SUPABASE_URL}|g\" {} \; && \
        sed -i \"s|url: 'http://127\.0\.0\.1:54321'|url: '${SUPABASE_URL}'|g\" /usr/share/nginx/html/supabase/config.js 2>/dev/null || true && \
        sed -i \"s|url: \\\"http://127\.0\.0\.1:54321\\\"|url: \\\"${SUPABASE_URL}\\\"|g\" /usr/share/nginx/html/supabase/config.js 2>/dev/null || true && \
        sed -i \"s|http://127\.0\.0\.1:54321|${SUPABASE_URL}|g\" /usr/share/nginx/html/supabase/config.js 2>/dev/null || true
    "
    
    echo -e "${GREEN}✓ URLs replaced in container${NC}"
    echo ""
    echo -e "${YELLOW}Note: Changes will be lost when container is rebuilt.${NC}"
    echo -e "${YELLOW}To make permanent, rebuild container with correct SUPABASE_URL in .env${NC}"
else
    echo -e "${GREEN}✓ No localhost URLs found${NC}"
fi

echo ""
echo -e "${BLUE}Checking config.js content:${NC}"
docker exec "$CONTAINER_NAME" cat /usr/share/nginx/html/supabase/config.js | grep -A 2 "SUPABASE_CONFIG" || true

echo ""
echo "=========================================="
echo -e "${CYAN}Verification Complete${NC}"
echo "=========================================="
echo ""
echo "To make changes permanent:"
echo "  1. Ensure SUPABASE_URL is set in .env file"
echo "  2. Rebuild container: docker compose -f docker-compose.prod.yml build web"
echo "  3. Restart: docker compose -f docker-compose.prod.yml up -d web"
echo ""
