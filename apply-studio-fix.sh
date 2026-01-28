#!/bin/bash

# Скрипт для применения обновления Studio с pg-meta
# Автоматически разрешает конфликты Git и перезапускает контейнеры

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Apply Studio Fix with pg-meta${NC}"
echo "=========================================="
echo ""

cd /opt/mediavelichia

# Шаг 1: Разрешаем конфликты Git
echo -e "${BLUE}Step 1: Resolving Git conflicts...${NC}"

# Проверяем есть ли локальные изменения
if [ -n "$(git status --porcelain docker-compose.prod.yml 2>/dev/null)" ]; then
    echo "Found local changes in docker-compose.prod.yml"
    echo "Discarding local changes and using remote version..."
    git checkout -- docker-compose.prod.yml
fi

# Обновляем код
echo "Pulling latest changes..."
git pull origin main

echo -e "${GREEN}✓ Code updated${NC}"
echo ""

# Шаг 2: Проверяем .env файл
echo -e "${BLUE}Step 2: Checking .env file...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file not found${NC}"
    echo "Copying from .env.example..."
    cp .env.example .env
    echo -e "${YELLOW}⚠ Please edit .env file with your actual values!${NC}"
else
    echo -e "${GREEN}✓ .env file exists${NC}"
fi

echo ""

# Шаг 3: Останавливаем старые контейнеры
echo -e "${BLUE}Step 3: Stopping old containers...${NC}"
docker compose -f docker-compose.prod.yml down

echo ""

# Шаг 4: Запускаем новые контейнеры
echo -e "${BLUE}Step 4: Starting containers with new configuration...${NC}"
docker compose -f docker-compose.prod.yml up -d

echo ""

# Шаг 5: Ждем запуска сервисов
echo -e "${BLUE}Step 5: Waiting for services to start...${NC}"
sleep 10

# Шаг 6: Проверяем статус контейнеров
echo ""
echo -e "${BLUE}Step 6: Checking container status...${NC}"
docker ps --filter "name=mediavelichie" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# Шаг 7: Проверяем логи pg-meta (новый сервис)
echo -e "${BLUE}Step 7: Checking pg-meta logs...${NC}"
echo ""
docker logs mediavelichie-supabase-meta --tail 20 2>&1 || echo "pg-meta container not found or not started yet"

echo ""

# Шаг 8: Проверяем логи Studio
echo -e "${BLUE}Step 8: Checking Studio logs...${NC}"
echo ""
docker logs mediavelichie-supabase-studio --tail 20 2>&1

echo ""
echo "=========================================="
echo -e "${CYAN}Update Complete${NC}"
echo "=========================================="
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Wait 30-60 seconds for all services to fully start"
echo "  2. Open Studio: http://194.58.88.127:3000"
echo "  3. Studio should automatically connect to PostgreSQL"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  Check all containers: docker ps | grep mediavelichie"
echo "  Check pg-meta logs: docker logs mediavelichie-supabase-meta"
echo "  Check Studio logs: docker logs mediavelichie-supabase-studio"
echo "  Restart Studio: docker compose -f docker-compose.prod.yml restart supabase-studio"
echo ""
