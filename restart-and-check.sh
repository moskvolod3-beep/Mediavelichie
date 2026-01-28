#!/bin/bash

# Скрипт для перезапуска Docker контейнеров и проверки работоспособности
# Использование: ./restart-and-check.sh [SERVER_IP]
# Если SERVER_IP не указан, будет использован автоматически определенный IP

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Пути
PROJECT_DIR="/opt/mediavelichia"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"

# Определяем IP адрес сервера
if [ -n "$1" ]; then
    SERVER_IP="$1"
else
    # Автоматически определяем IP адрес
    SERVER_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    fi
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="127.0.0.1"
        echo -e "${YELLOW}Warning: Could not determine server IP, using localhost${NC}"
    fi
fi

echo "=========================================="
echo -e "${CYAN}Docker Restart and Health Check${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Server IP:${NC} $SERVER_IP"
echo -e "${BLUE}Project directory:${NC} $PROJECT_DIR"
echo ""

# Проверка существования файлов
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: Docker Compose file not found: $COMPOSE_FILE${NC}"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Функция проверки доступности порта
check_port() {
    local HOST=$1
    local PORT=$2
    local SERVICE=$3
    
    if command -v nc &> /dev/null; then
        # Используем netcat
        if nc -z -w 2 "$HOST" "$PORT" 2>/dev/null; then
            return 0
        fi
    elif command -v timeout &> /dev/null && command -v bash &> /dev/null; then
        # Используем timeout с bash
        if timeout 2 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
            return 0
        fi
    elif command -v curl &> /dev/null; then
        # Используем curl для HTTP портов
        if [ "$PORT" = "80" ] || [ "$PORT" = "3000" ] || [ "$PORT" = "5000" ]; then
            if curl -s --connect-timeout 2 "http://$HOST:$PORT" > /dev/null 2>&1; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Функция проверки HTTP ответа
check_http() {
    local URL=$1
    local SERVICE=$2
    
    if command -v curl &> /dev/null; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$URL" 2>/dev/null || echo "000")
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget --spider --timeout=5 --quiet "$URL" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# Шаг 1: Остановка контейнеров
echo -e "${BLUE}Step 1: Stopping containers...${NC}"
docker compose -f "$COMPOSE_FILE" down
echo ""

# Шаг 2: Запуск контейнеров
echo -e "${BLUE}Step 2: Starting containers...${NC}"
docker compose -f "$COMPOSE_FILE" up -d
echo ""

# Шаг 3: Ожидание запуска контейнеров
echo -e "${BLUE}Step 3: Waiting for containers to start...${NC}"
echo "This may take 30-60 seconds..."
sleep 10

# Проверяем статус контейнеров несколько раз
MAX_WAIT=60
WAITED=0
ALL_HEALTHY=false

while [ $WAITED -lt $MAX_WAIT ]; do
    HEALTHY_COUNT=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep -c '"Health":"healthy"' || echo "0")
    TOTAL_COUNT=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep -c '"State":"running"' || echo "0")
    
    if [ "$HEALTHY_COUNT" -ge 1 ] && [ "$TOTAL_COUNT" -ge 3 ]; then
        ALL_HEALTHY=true
        break
    fi
    
    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
done

echo ""
echo ""

# Шаг 4: Проверка статуса контейнеров
echo -e "${BLUE}Step 4: Container Status${NC}"
echo "=========================================="
docker compose -f "$COMPOSE_FILE" ps
echo ""

# Шаг 5: Проверка доступности сервисов
echo -e "${BLUE}Step 5: Service Availability Check${NC}"
echo "=========================================="
echo ""

# Проверка Web (порт 80)
echo -n "Checking Web (HTTP port 80)... "
if check_http "http://$SERVER_IP" "Web"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "  URL: http://$SERVER_IP"
    WEB_OK=true
else
    echo -e "${RED}✗ FAILED${NC}"
    WEB_OK=false
fi

# Проверка Supabase PostgreSQL (порт 5432)
echo -n "Checking Supabase PostgreSQL (port 5432)... "
if check_port "$SERVER_IP" 5432 "Supabase"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "  Connection: $SERVER_IP:5432"
    SUPABASE_OK=true
else
    echo -e "${RED}✗ FAILED${NC}"
    SUPABASE_OK=false
fi

# Проверка Supabase Studio (порт 3000)
echo -n "Checking Supabase Studio (port 3000)... "
if check_http "http://$SERVER_IP:3000" "Supabase Studio"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "  URL: http://$SERVER_IP:3000"
    STUDIO_OK=true
else
    echo -e "${YELLOW}⚠ WARNING${NC} (may need more time to start)"
    STUDIO_OK=false
fi

# Проверка Editor (порт 5000)
echo -n "Checking Editor (port 5000)... "
if check_http "http://$SERVER_IP:5000" "Editor"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "  URL: http://$SERVER_IP:5000"
    EDITOR_OK=true
else
    echo -e "${YELLOW}⚠ WARNING${NC} (may need more time to start)"
    EDITOR_OK=false
fi

echo ""

# Шаг 6: Итоговый отчет
echo "=========================================="
echo -e "${CYAN}Health Check Summary${NC}"
echo "=========================================="
echo ""

if [ "$WEB_OK" = true ]; then
    echo -e "Web (HTTP):        ${GREEN}✓ Available${NC} - http://$SERVER_IP"
else
    echo -e "Web (HTTP):        ${RED}✗ Not Available${NC}"
fi

if [ "$SUPABASE_OK" = true ]; then
    echo -e "Supabase (DB):     ${GREEN}✓ Available${NC} - $SERVER_IP:5432"
else
    echo -e "Supabase (DB):     ${RED}✗ Not Available${NC}"
fi

if [ "$STUDIO_OK" = true ]; then
    echo -e "Supabase Studio:   ${GREEN}✓ Available${NC} - http://$SERVER_IP:3000"
else
    echo -e "Supabase Studio:   ${YELLOW}⚠ Checking...${NC} - http://$SERVER_IP:3000"
fi

if [ "$EDITOR_OK" = true ]; then
    echo -e "Editor:            ${GREEN}✓ Available${NC} - http://$SERVER_IP:5000"
else
    echo -e "Editor:            ${YELLOW}⚠ Checking...${NC} - http://$SERVER_IP:5000"
fi

echo ""

# Проверка логов если есть проблемы
if [ "$WEB_OK" = false ] || [ "$SUPABASE_OK" = false ]; then
    echo -e "${YELLOW}Checking logs for errors...${NC}"
    echo ""
    
    if [ "$WEB_OK" = false ]; then
        echo -e "${BLUE}Web container logs (last 20 lines):${NC}"
        docker compose -f "$COMPOSE_FILE" logs --tail=20 web 2>/dev/null || echo "No logs available"
        echo ""
    fi
    
    if [ "$SUPABASE_OK" = false ]; then
        echo -e "${BLUE}Supabase container logs (last 20 lines):${NC}"
        docker compose -f "$COMPOSE_FILE" logs --tail=20 supabase 2>/dev/null || echo "No logs available"
        echo ""
    fi
fi

# Итоговый статус
echo "=========================================="
if [ "$WEB_OK" = true ] && [ "$SUPABASE_OK" = true ]; then
    echo -e "${GREEN}✓ Core services are running!${NC}"
    echo ""
    echo -e "${CYAN}Access URLs:${NC}"
    echo "  Website:        http://$SERVER_IP"
    echo "  Supabase DB:    $SERVER_IP:5432"
    echo "  Supabase Studio: http://$SERVER_IP:3000"
    echo "  Editor:         http://$SERVER_IP:5000"
    echo ""
    echo -e "${GREEN}Restart completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some services are not available${NC}"
    echo ""
    echo "Please check the logs above and try again."
    echo "You can view logs with: docker compose -f $COMPOSE_FILE logs -f"
    exit 1
fi
