#!/bin/bash

# Скрипт для замены локальных URL на серверные в frontend файлах
# Использование: ./replace-localhost-urls.sh [SUPABASE_URL]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

FRONTEND_DIR="./frontend"

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
        echo "Usage: ./replace-localhost-urls.sh [SUPABASE_URL]"
        echo ""
        echo "Example:"
        echo "  ./replace-localhost-urls.sh https://your-project.supabase.co"
        echo ""
        echo "Or set SUPABASE_URL in .env file"
        exit 1
    fi
fi

# Убираем завершающий слеш если есть
SUPABASE_URL=$(echo "$SUPABASE_URL" | sed 's:/*$::')

echo "=========================================="
echo -e "${CYAN}Replacing Localhost URLs${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Frontend directory:${NC} $FRONTEND_DIR"
echo -e "${BLUE}Supabase URL:${NC} $SUPABASE_URL"
echo ""

if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}Error: Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

# Счетчик замен
REPLACEMENT_COUNT=0

# Функция замены в файле
replace_in_file() {
    local FILE=$1
    local OLD_URL=$2
    local NEW_URL=$3
    
    if [ -f "$FILE" ]; then
        # Создаем резервную копию
        cp "$FILE" "$FILE.bak"
        
        # Заменяем URL
        if sed -i.tmp "s|$OLD_URL|$NEW_URL|g" "$FILE" 2>/dev/null; then
            rm -f "$FILE.tmp"
            REPLACEMENT_COUNT=$((REPLACEMENT_COUNT + 1))
            echo -e "${GREEN}✓${NC} Updated: $FILE"
            return 0
        else
            # Восстанавливаем из резервной копии
            mv "$FILE.bak" "$FILE"
            return 1
        fi
    fi
}

# Заменяем в HTML файлах
echo -e "${BLUE}Replacing URLs in HTML files...${NC}"
for FILE in "$FRONTEND_DIR"/*.html; do
    if [ -f "$FILE" ]; then
        # Заменяем http://127.0.0.1:54321
        replace_in_file "$FILE" "http://127.0.0.1:54321" "$SUPABASE_URL"
        # Заменяем http://localhost:54321
        replace_in_file "$FILE" "http://localhost:54321" "$SUPABASE_URL"
    fi
done

# Заменяем в JavaScript файлах
echo ""
echo -e "${BLUE}Replacing URLs in JavaScript files...${NC}"
for FILE in "$FRONTEND_DIR"/js/*.js; do
    if [ -f "$FILE" ]; then
        replace_in_file "$FILE" "http://127.0.0.1:54321" "$SUPABASE_URL"
        replace_in_file "$FILE" "http://localhost:54321" "$SUPABASE_URL"
    fi
done

# Обновляем конфигурационный файл
echo ""
echo -e "${BLUE}Updating Supabase configuration...${NC}"
CONFIG_FILE="$FRONTEND_DIR/supabase/config.js"
if [ -f "$CONFIG_FILE" ]; then
    # Создаем резервную копию
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    
    # Заменяем URL в конфиге
    sed -i.tmp "s|url: 'http://127.0.0.1:54321'|url: '$SUPABASE_URL'|g" "$CONFIG_FILE"
    sed -i.tmp "s|url: \"http://127.0.0.1:54321\"|url: \"$SUPABASE_URL\"|g" "$CONFIG_FILE"
    
    rm -f "$CONFIG_FILE.tmp"
    echo -e "${GREEN}✓${NC} Updated: $CONFIG_FILE"
    REPLACEMENT_COUNT=$((REPLACEMENT_COUNT + 1))
fi

# Обновляем project.html специально (там есть переменная supabaseBaseUrl)
PROJECT_FILE="$FRONTEND_DIR/project.html"
if [ -f "$PROJECT_FILE" ]; then
    cp "$PROJECT_FILE" "$PROJECT_FILE.bak"
    sed -i.tmp "s|let supabaseBaseUrl = 'http://127.0.0.1:54321'|let supabaseBaseUrl = '$SUPABASE_URL'|g" "$PROJECT_FILE"
    sed -i.tmp "s|let supabaseBaseUrl = \"http://127.0.0.1:54321\"|let supabaseBaseUrl = \"$SUPABASE_URL\"|g" "$PROJECT_FILE"
    rm -f "$PROJECT_FILE.tmp"
    echo -e "${GREEN}✓${NC} Updated: $PROJECT_FILE"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Replacement completed!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Files updated:${NC} $REPLACEMENT_COUNT"
echo ""
echo -e "${YELLOW}Note:${NC} Backup files (.bak) were created. You can remove them after verification."
echo ""
echo "Next steps:"
echo "  1. Review the changes"
echo "  2. Test the website"
echo "  3. Remove .bak files: find $FRONTEND_DIR -name '*.bak' -delete"
echo ""
