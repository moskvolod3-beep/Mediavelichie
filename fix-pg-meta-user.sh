#!/bin/bash

# Скрипт для проверки и исправления пользователя БД для pg-meta
# Проблема: pg-meta может пытаться подключиться как supabase_admin, которого нет

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Fix pg-meta Database User${NC}"
echo "=========================================="
echo ""

cd /opt/mediavelichia

# Проверяем какие пользователи есть в БД
echo -e "${BLUE}Checking database users...${NC}"
DB_USERS=$(docker exec mediavelichie-supabase-db psql -U postgres -t -c "SELECT usename FROM pg_user;" 2>&1 | tr -d ' ')

echo "Available users:"
echo "$DB_USERS"
echo ""

# Проверяем существует ли supabase_admin
if echo "$DB_USERS" | grep -q "supabase_admin"; then
    echo -e "${GREEN}✓ supabase_admin user exists${NC}"
    USE_USER="supabase_admin"
else
    echo -e "${YELLOW}⚠ supabase_admin user NOT found${NC}"
    echo "Using postgres user instead..."
    USE_USER="postgres"
fi

echo ""
echo -e "${BLUE}Updating docker-compose.prod.yml...${NC}"

# Обновляем docker-compose.prod.yml чтобы использовать правильного пользователя
sed -i "s/PG_META_DB_USER: supabase_admin/PG_META_DB_USER: $USE_USER/g" docker-compose.prod.yml

echo -e "${GREEN}✓ Configuration updated${NC}"
echo ""

# Перезапускаем pg-meta
echo -e "${BLUE}Restarting pg-meta container...${NC}"
docker compose -f docker-compose.prod.yml restart supabase-meta

echo ""
echo "Waiting 10 seconds for pg-meta to start..."
sleep 10

# Проверяем логи
echo ""
echo -e "${BLUE}Checking pg-meta logs...${NC}"
docker logs mediavelichie-supabase-meta --tail 30

echo ""
echo "=========================================="
echo -e "${CYAN}Fix Complete${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Check Studio: http://194.58.88.127:3000"
echo "  2. If still errors, check logs: docker logs mediavelichie-supabase-meta"
echo "  3. Restart Studio: docker compose -f docker-compose.prod.yml restart supabase-studio"
echo ""
