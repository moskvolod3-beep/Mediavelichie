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

# Проверяем что Studio может подключиться к БД
CONNECTION_TEST=$(docker exec "$STUDIO_CONTAINER" sh -c "nc -zv supabase 5432 2>&1" || echo "failed")

if echo "$CONNECTION_TEST" | grep -q "succeeded\|open"; then
    echo -e "${GREEN}✓ Network connection: OK${NC}"
else
    echo -e "${RED}✗ Network connection: FAILED${NC}"
    echo "  $CONNECTION_TEST"
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

# Тестируем подключение из Studio контейнера
PG_TEST=$(docker exec "$STUDIO_CONTAINER" sh -c "PGPASSWORD='$POSTGRES_PASSWORD' psql -h supabase -U postgres -d postgres -c 'SELECT version();' 2>&1" || echo "failed")

if echo "$PG_TEST" | grep -q "PostgreSQL\|version"; then
    echo -e "${GREEN}✓ PostgreSQL connection: OK${NC}"
    echo "$PG_TEST" | head -3
else
    echo -e "${RED}✗ PostgreSQL connection: FAILED${NC}"
    echo "  $PG_TEST"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  1. Check that both containers are on the same network"
    echo "  2. Verify POSTGRES_PASSWORD matches in both containers"
    echo "  3. Check Studio logs: docker logs $STUDIO_CONTAINER"
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
echo ""
