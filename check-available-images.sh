#!/bin/bash

# Скрипт для проверки доступных образов Supabase Studio

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Check Available Supabase Images${NC}"
echo "=========================================="
echo ""

echo -e "${BLUE}Checking Supabase Studio images...${NC}"
echo ""

# Пробуем разные теги
TAGS=("latest" "20240205-b145c86" "20231220-0a8c4b5")

for TAG in "${TAGS[@]}"; do
    echo -n "Testing supabase/studio:$TAG... "
    if docker pull supabase/studio:$TAG > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Available${NC}"
        docker rmi supabase/studio:$TAG > /dev/null 2>&1 || true
    else
        echo -e "${RED}✗ Not found${NC}"
    fi
done

echo ""
echo -e "${BLUE}Checking pgAdmin image...${NC}"
echo -n "Testing dpage/pgadmin4:latest... "
if docker pull dpage/pgadmin4:latest > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Available${NC}"
    docker rmi dpage/pgadmin4:latest > /dev/null 2>&1 || true
else
    echo -e "${RED}✗ Not found${NC}"
fi

echo ""
echo "=========================================="
echo -e "${CYAN}Recommendation${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}If Studio images are not available, use pgAdmin instead:${NC}"
echo "  docker compose -f docker-compose.prod.yml up -d pgadmin"
echo ""
echo "pgAdmin is more reliable for standalone PostgreSQL."
echo ""
