#!/bin/bash

# Скрипт для исправления проблемы с подключением pg-meta к БД
# Проблема: pg-meta пытается подключиться к 'db' вместо 'supabase'

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Fix pg-meta Host Configuration${NC}"
echo "=========================================="
echo ""

cd /opt/mediavelichia

# Проверяем текущую конфигурацию
echo -e "${BLUE}Checking current configuration...${NC}"
CURRENT_HOST=$(grep "PG_META_DB_HOST" docker-compose.prod.yml | head -1 | awk '{print $2}' | tr -d ':')

echo "Current PG_META_DB_HOST: $CURRENT_HOST"
echo ""

# Проверяем имя сервиса PostgreSQL
echo -e "${BLUE}Checking PostgreSQL service name...${NC}"
DB_SERVICE=$(grep -A 5 "^  supabase:" docker-compose.prod.yml | head -1 | awk '{print $2}' | tr -d ':')
echo "PostgreSQL service name: $DB_SERVICE"
echo ""

if [ "$CURRENT_HOST" != "$DB_SERVICE" ]; then
    echo -e "${YELLOW}⚠ Host mismatch detected!${NC}"
    echo "Updating configuration..."
    
    # Обновляем конфигурацию
    sed -i "s/PG_META_DB_HOST:.*/PG_META_DB_HOST: $DB_SERVICE/g" docker-compose.prod.yml
    
    echo -e "${GREEN}✓ Configuration updated${NC}"
else
    echo -e "${GREEN}✓ Configuration is correct${NC}"
fi

echo ""

# Проверяем что контейнеры в одной сети
echo -e "${BLUE}Checking Docker network...${NC}"
NETWORK_CHECK=$(docker network inspect mediavelichie-network --format '{{range .Containers}}{{.Name}} {{end}}' 2>&1 | grep -E "supabase|meta" || echo "Not found")

if echo "$NETWORK_CHECK" | grep -q "supabase-db\|supabase-meta"; then
    echo -e "${GREEN}✓ Both containers in network${NC}"
    echo "  $NETWORK_CHECK"
else
    echo -e "${YELLOW}⚠ Network issue detected${NC}"
    echo "  $NETWORK_CHECK"
fi

echo ""

# Перезапускаем pg-meta
echo -e "${BLUE}Restarting pg-meta container...${NC}"
docker compose -f docker-compose.prod.yml restart supabase-meta

echo "Waiting 15 seconds for pg-meta to start..."
sleep 15

# Проверяем логи
echo ""
echo -e "${BLUE}Checking pg-meta logs (last 20 lines)...${NC}"
docker logs mediavelichie-supabase-meta --tail 20 2>&1 | tail -10

echo ""
echo "=========================================="
echo -e "${CYAN}Fix Complete${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Check Studio: http://194.58.88.127:3000"
echo "  2. If errors persist, check full logs: docker logs mediavelichie-supabase-meta"
echo "  3. Verify connection: docker exec mediavelichie-supabase-meta ping -c 2 supabase"
echo ""
