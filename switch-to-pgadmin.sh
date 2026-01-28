#!/bin/bash

# Скрипт для переключения с Studio на pgAdmin
# pgAdmin более стабилен для работы с обычным PostgreSQL

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Switch to pgAdmin${NC}"
echo "=========================================="
echo ""

cd /opt/mediavelichia

# Останавливаем Studio и pg-meta
echo -e "${BLUE}Stopping Studio and pg-meta...${NC}"
docker compose -f docker-compose.prod.yml stop supabase-studio supabase-meta 2>/dev/null || true

# Добавляем pgAdmin в docker-compose.prod.yml
echo -e "${BLUE}Adding pgAdmin configuration...${NC}"

# Проверяем есть ли уже pgAdmin
if grep -q "pgadmin:" docker-compose.prod.yml; then
    echo -e "${YELLOW}pgAdmin already configured${NC}"
else
    # Добавляем pgAdmin перед volumes
    sed -i '/^volumes:/i\
  # ============================================\
  # pgAdmin: Альтернативный веб-интерфейс для PostgreSQL\
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

# Запускаем pgAdmin
echo ""
echo -e "${BLUE}Starting pgAdmin...${NC}"
docker compose -f docker-compose.prod.yml up -d pgadmin

echo ""
echo "Waiting 10 seconds for pgAdmin to start..."
sleep 10

# Проверяем статус
echo ""
echo -e "${BLUE}Checking pgAdmin status...${NC}"
docker ps --filter "name=pgadmin" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

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
echo "  Password: admin123 (или из .env: PGADMIN_PASSWORD)"
echo ""
echo -e "${BLUE}To connect to PostgreSQL:${NC}"
echo "  1. Login to pgAdmin"
echo "  2. Right-click 'Servers' → 'Register' → 'Server'"
echo "  3. General tab: Name = Mediavelichia"
echo "  4. Connection tab:"
echo "     - Host: supabase (или 194.58.88.127)"
echo "     - Port: 5432"
echo "     - Database: postgres"
echo "     - Username: postgres"
echo "     - Password: из .env файла"
echo ""
