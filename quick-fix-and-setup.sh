#!/bin/bash

# Быстрое исправление конфликтов и настройка pgAdmin

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Quick Fix and Setup${NC}"
echo "=========================================="
echo ""

cd /opt/mediavelichia

# Шаг 1: Разрешаем конфликты Git
echo -e "${BLUE}Step 1: Resolving Git conflicts...${NC}"
git checkout -- docker-compose.prod.yml 2>/dev/null || true
git pull origin main

echo -e "${GREEN}✓ Code updated${NC}"
echo ""

# Шаг 2: Добавляем pgAdmin в docker-compose.prod.yml
echo -e "${BLUE}Step 2: Adding pgAdmin configuration...${NC}"

if grep -q "pgadmin:" docker-compose.prod.yml; then
    echo -e "${YELLOW}pgAdmin already configured${NC}"
else
    # Добавляем pgAdmin перед volumes
    sed -i '/^volumes:/i\
  # ============================================\
  # pgAdmin: Веб-интерфейс для управления PostgreSQL\
  # Доступен через браузер: http://localhost:5050\
  # ============================================\
  pgadmin:\
    image: dpage/pgadmin4:latest\
    container_name: mediavelichie-pgadmin\
    ports:\
      - "5050:80"\
    environment:\
      PGADMIN_DEFAULT_EMAIL: admin@example.com\
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin123}\
      PGADMIN_CONFIG_SERVER_MODE: '\''False'\''\
    depends_on:\
      supabase:\
        condition: service_healthy\
    restart: unless-stopped\
    networks:\
      - mediavelichie-network\
' docker-compose.prod.yml
    
    echo -e "${GREEN}✓ pgAdmin configuration added${NC}"
fi

echo ""

# Шаг 3: Останавливаем проблемные контейнеры
echo -e "${BLUE}Step 3: Stopping problematic containers...${NC}"
docker compose -f docker-compose.prod.yml stop supabase-studio supabase-meta 2>/dev/null || true

echo ""

# Шаг 4: Запускаем pgAdmin
echo -e "${BLUE}Step 4: Starting pgAdmin...${NC}"
docker compose -f docker-compose.prod.yml up -d pgadmin

echo ""
echo "Waiting 10 seconds for pgAdmin to start..."
sleep 10

# Шаг 5: Проверяем статус
echo ""
echo -e "${BLUE}Step 5: Checking status...${NC}"
docker ps --filter "name=mediavelichie" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=========================================="
echo -e "${CYAN}Setup Complete${NC}"
echo "=========================================="
echo ""
echo -e "${GREEN}pgAdmin is now available at:${NC}"
echo "  http://194.58.88.127:5050"
echo ""
echo -e "${BLUE}Login credentials:${NC}"
echo "  Email: admin@example.com"
echo "  Password: admin123"
echo ""
echo -e "${BLUE}To connect to PostgreSQL:${NC}"
echo "  1. Login to pgAdmin"
echo "  2. Right-click 'Servers' → 'Register' → 'Server'"
echo "  3. General tab: Name = Mediavelichia"
echo "  4. Connection tab:"
echo "     - Host: supabase"
echo "     - Port: 5432"
echo "     - Database: postgres"
echo "     - Username: postgres"
echo "     - Password: $(grep POSTGRES_PASSWORD .env 2>/dev/null | cut -d '=' -f2 || echo 'from .env file')"
echo ""
