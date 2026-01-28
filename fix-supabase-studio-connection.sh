#!/bin/bash

# Скрипт для проверки и исправления подключения Supabase Studio к PostgreSQL
# Использование: ./fix-supabase-studio-connection.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

COMPOSE_FILE="docker-compose.prod.yml"
STUDIO_CONTAINER="mediavelichie-supabase-studio"
DB_CONTAINER="mediavelichie-supabase-db"

echo "=========================================="
echo -e "${CYAN}Fix Supabase Studio Connection${NC}"
echo "=========================================="
echo ""

# Проверяем что контейнеры запущены
if ! docker ps --format '{{.Names}}' | grep -q "^${STUDIO_CONTAINER}$"; then
    echo -e "${RED}Error: Supabase Studio container is not running${NC}"
    echo "Start it with: docker compose -f $COMPOSE_FILE up -d supabase-studio"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo -e "${RED}Error: PostgreSQL container is not running${NC}"
    echo "Start it with: docker compose -f $COMPOSE_FILE up -d supabase"
    exit 1
fi

# Проверяем подключение из Studio к БД
echo -e "${BLUE}Testing connection from Studio to PostgreSQL...${NC}"
echo ""

# Метод 1: Используем ping для проверки сети
PING_TEST=$(docker exec "$STUDIO_CONTAINER" sh -c "ping -c 2 supabase 2>&1" || echo "failed")
if echo "$PING_TEST" | grep -q "2 packets transmitted\|PING"; then
    echo -e "${GREEN}✓ Network ping: OK${NC}"
    NETWORK_OK=true
else
    echo -e "${YELLOW}⚠ Network ping: Could not test (ping not available)${NC}"
    NETWORK_OK=unknown
fi

# Метод 2: Проверяем доступность порта через timeout (если доступен)
PORT_TEST=$(docker exec "$STUDIO_CONTAINER" sh -c "timeout 2 sh -c '</dev/tcp/supabase/5432' 2>&1" || echo "failed")
if [ "$PORT_TEST" = "" ] || echo "$PORT_TEST" | grep -q "timeout\|Connection refused"; then
    if [ "$PORT_TEST" = "" ]; then
        echo -e "${GREEN}✓ Port 5432 accessible: OK${NC}"
        PORT_OK=true
    else
        echo -e "${RED}✗ Port 5432: FAILED${NC}"
        echo "  $PORT_TEST"
        PORT_OK=false
    fi
else
    echo -e "${YELLOW}⚠ Port check: Could not test (timeout/sh not available)${NC}"
    PORT_OK=unknown
fi

# Проверяем переменные окружения в Studio
echo ""
echo -e "${BLUE}Checking Studio environment variables...${NC}"
docker exec "$STUDIO_CONTAINER" env | grep POSTGRES || echo "No POSTGRES variables found"

echo ""

# Проверяем подключение к БД с паролем
echo -e "${BLUE}Testing PostgreSQL connection...${NC}"

# Получаем пароль из .env или из переменных контейнера
if [ -f ".env" ]; then
    POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
else
    POSTGRES_PASSWORD=$(docker exec "$DB_CONTAINER" env | grep POSTGRES_PASSWORD | cut -d '=' -f2)
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
    echo -e "${YELLOW}Warning: Could not determine POSTGRES_PASSWORD${NC}"
    POSTGRES_PASSWORD="your-super-secret-postgres-password-change-me"
fi

# Тестируем подключение к PostgreSQL из контейнера БД (более надежно)
echo -e "${BLUE}Testing PostgreSQL from DB container...${NC}"
PG_VERSION=$(docker exec "$DB_CONTAINER" psql -U postgres -d postgres -t -c "SELECT version();" 2>&1 | head -1)
if echo "$PG_VERSION" | grep -q "PostgreSQL"; then
    echo -e "${GREEN}✓ PostgreSQL is running: OK${NC}"
    echo "  $PG_VERSION" | head -1
else
    echo -e "${RED}✗ PostgreSQL check: FAILED${NC}"
    echo "  $PG_VERSION"
fi

# Проверяем что пароли совпадают
echo ""
echo -e "${BLUE}Verifying password consistency...${NC}"
DB_PASSWORD=$(docker exec "$DB_CONTAINER" env | grep "^POSTGRES_PASSWORD=" | cut -d '=' -f2- | tr -d '"' | tr -d "'")
STUDIO_PASSWORD=$(docker exec "$STUDIO_CONTAINER" env | grep "^POSTGRES_PASSWORD=" | cut -d '=' -f2- | tr -d '"' | tr -d "'")

if [ "$DB_PASSWORD" = "$STUDIO_PASSWORD" ] && [ -n "$DB_PASSWORD" ]; then
    echo -e "${GREEN}✓ Passwords match: OK${NC}"
    PASSWORD_MATCH=true
else
    echo -e "${RED}✗ Passwords do NOT match or are empty${NC}"
    echo "  DB password length: ${#DB_PASSWORD}"
    echo "  Studio password length: ${#STUDIO_PASSWORD}"
    PASSWORD_MATCH=false
fi

# Проверяем что контейнеры в одной сети
echo ""
echo -e "${BLUE}Checking Docker network...${NC}"
NETWORK_CHECK=$(docker network inspect mediavelichie-network --format '{{range .Containers}}{{.Name}} {{end}}' 2>&1)
if echo "$NETWORK_CHECK" | grep -q "$STUDIO_CONTAINER" && echo "$NETWORK_CHECK" | grep -q "$DB_CONTAINER"; then
    echo -e "${GREEN}✓ Both containers in same network: OK${NC}"
    echo "  Network: mediavelichie-network"
    echo "  Containers: $NETWORK_CHECK"
    NETWORK_MATCH=true
else
    echo -e "${RED}✗ Containers not in same network${NC}"
    echo "  $NETWORK_CHECK"
    NETWORK_MATCH=false
fi

echo ""
echo "=========================================="
echo -e "${CYAN}Summary${NC}"
echo "=========================================="

if [ "$PASSWORD_MATCH" = true ] && [ "$NETWORK_MATCH" = true ]; then
    echo -e "${GREEN}✓ Configuration looks correct${NC}"
    echo ""
    echo -e "${YELLOW}If Studio still can't connect, check:${NC}"
    echo "  1. Studio logs for connection errors"
    echo "  2. That PostgreSQL is accepting connections"
    echo "  3. Firewall rules (if any)"
else
    echo -e "${RED}✗ Configuration issues detected${NC}"
    if [ "$PASSWORD_MATCH" != true ]; then
        echo "  - Passwords don't match"
    fi
    if [ "$NETWORK_MATCH" != true ]; then
        echo "  - Containers not in same network"
    fi
fi

echo ""
echo "=========================================="
echo -e "${CYAN}Connection Check Complete${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  Check Studio logs: docker logs $STUDIO_CONTAINER"
echo "  Check DB logs: docker logs $DB_CONTAINER"
echo "  Restart Studio: docker compose -f $COMPOSE_FILE restart supabase-studio"
echo "  Check Studio logs (last 50 lines): docker logs --tail 50 $STUDIO_CONTAINER"
echo ""
