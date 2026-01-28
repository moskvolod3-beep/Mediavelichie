#!/bin/bash

# Скрипт для исправления Supabase URL в .env файле
# Использование: ./fix-supabase-url.sh [SUPABASE_URL]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ENV_FILE=".env"

echo "=========================================="
echo -e "${CYAN}Fix Supabase URL in .env${NC}"
echo "=========================================="
echo ""

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Проверяем текущий URL
CURRENT_URL=$(grep "^SUPABASE_URL=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs || echo "")

if [ -n "$CURRENT_URL" ]; then
    echo -e "${BLUE}Current SUPABASE_URL:${NC} $CURRENT_URL"
else
    echo -e "${YELLOW}SUPABASE_URL not found in .env${NC}"
fi

echo ""

# Определяем новый URL
if [ -n "$1" ]; then
    NEW_URL="$1"
else
    # Проверяем что используется: локальный или облачный
    if echo "$CURRENT_URL" | grep -q "5432"; then
        echo -e "${YELLOW}Detected PostgreSQL port (5432) instead of Supabase API port${NC}"
        echo ""
        echo "Options:"
        echo "  1. Use cloud Supabase (recommended for production)"
        echo "  2. Use local Supabase on port 54321 (requires full Supabase stack)"
        echo ""
        read -p "Enter Supabase URL (or press Enter to use http://194.58.88.127:54321): " NEW_URL
        
        if [ -z "$NEW_URL" ]; then
            NEW_URL="http://194.58.88.127:54321"
        fi
    else
        echo "Please provide Supabase URL:"
        echo "  Cloud: https://your-project-id.supabase.co"
        echo "  Local: http://194.58.88.127:54321"
        read -p "Supabase URL: " NEW_URL
        
        if [ -z "$NEW_URL" ]; then
            echo -e "${RED}Error: URL is required${NC}"
            exit 1
        fi
    fi
fi

# Убираем завершающий слеш
NEW_URL=$(echo "$NEW_URL" | sed 's:/*$::')

echo ""
echo -e "${BLUE}New SUPABASE_URL:${NC} $NEW_URL"
echo ""

# Создаем резервную копию
cp "$ENV_FILE" "$ENV_FILE.bak"
echo -e "${GREEN}✓ Backup created: ${ENV_FILE}.bak${NC}"

# Заменяем или добавляем SUPABASE_URL
if grep -q "^SUPABASE_URL=" "$ENV_FILE"; then
    # Заменяем существующий
    sed -i "s|^SUPABASE_URL=.*|SUPABASE_URL=${NEW_URL}|g" "$ENV_FILE"
    echo -e "${GREEN}✓ Updated SUPABASE_URL${NC}"
else
    # Добавляем новый
    echo "SUPABASE_URL=${NEW_URL}" >> "$ENV_FILE"
    echo -e "${GREEN}✓ Added SUPABASE_URL${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ .env file updated!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Rebuild Docker container:"
echo "     docker compose -f docker-compose.prod.yml build web"
echo ""
echo "  2. Restart container:"
echo "     docker compose -f docker-compose.prod.yml up -d web"
echo ""
echo "  3. Verify configuration:"
echo "     docker exec mediavelichie-web cat /usr/share/nginx/html/supabase/config.js | grep url"
echo ""
