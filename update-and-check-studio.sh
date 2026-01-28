#!/bin/bash

# Скрипт для обновления кода и проверки Supabase Studio
# Использование: ./update-and-check-studio.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Update and Check Supabase Studio${NC}"
echo "=========================================="
echo ""

# Шаг 1: Разрешаем конфликты Git
echo -e "${BLUE}Step 1: Resolving Git conflicts...${NC}"
cd /opt/mediavelichia

# Сохраняем локальные изменения если есть
if [ -n "$(git status --porcelain fix-supabase-studio-connection.sh 2>/dev/null)" ]; then
    echo "Stashing local changes to fix-supabase-studio-connection.sh..."
    git stash push -m "Local changes before update $(date)" fix-supabase-studio-connection.sh || true
fi

# Обновляем код
echo "Pulling latest changes..."
git pull origin main

echo -e "${GREEN}✓ Code updated${NC}"
echo ""

# Шаг 2: Делаем скрипты исполняемыми
echo -e "${BLUE}Step 2: Making scripts executable...${NC}"
chmod +x fix-supabase-studio-connection.sh check-studio-logs.sh 2>/dev/null || true
echo -e "${GREEN}✓ Scripts ready${NC}"
echo ""

# Шаг 3: Проверяем логи Studio
echo -e "${BLUE}Step 3: Checking Studio logs...${NC}"
echo ""
docker logs mediavelichie-supabase-studio --tail 50 2>&1 | tail -30

echo ""
echo "=========================================="
echo -e "${CYAN}Running improved diagnostics...${NC}"
echo "=========================================="
echo ""

# Шаг 4: Запускаем улучшенную диагностику
./fix-supabase-studio-connection.sh

echo ""
echo "=========================================="
echo -e "${CYAN}Complete${NC}"
echo "=========================================="
