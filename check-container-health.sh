#!/bin/bash

# Скрипт для проверки здоровья контейнеров и исправления проблем
# Использование: ./check-container-health.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

COMPOSE_FILE="docker-compose.prod.yml"

echo "=========================================="
echo -e "${CYAN}Container Health Check${NC}"
echo "=========================================="
echo ""

# Проверка статуса контейнеров
echo -e "${BLUE}Container Status:${NC}"
docker compose -f "$COMPOSE_FILE" ps
echo ""

# Проверка каждого контейнера
echo -e "${BLUE}Detailed Health Check:${NC}"
echo ""

# Web container
echo -n "Web container (mediavelichie-web)... "
WEB_STATUS=$(docker inspect --format='{{.State.Health.Status}}' mediavelichie-web 2>/dev/null || echo "no-healthcheck")
if [ "$WEB_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Healthy${NC}"
elif [ "$WEB_STATUS" = "unhealthy" ]; then
    echo -e "${YELLOW}⚠ Unhealthy${NC}"
    echo "  Checking logs..."
    docker logs --tail=20 mediavelichie-web 2>&1 | tail -5
elif [ "$WEB_STATUS" = "no-healthcheck" ]; then
    echo -e "${YELLOW}⚠ No healthcheck configured${NC}"
else
    echo -e "${YELLOW}⚠ Status: $WEB_STATUS${NC}"
fi

# Проверка доступности веб-сайта
echo -n "  HTTP availability... "
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost/ | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi
echo ""

# Supabase Studio container
echo -n "Supabase Studio (mediavelichie-supabase-studio)... "
STUDIO_STATUS=$(docker inspect --format='{{.State.Health.Status}}' mediavelichie-supabase-studio 2>/dev/null || echo "no-healthcheck")
if [ "$STUDIO_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Healthy${NC}"
elif [ "$STUDIO_STATUS" = "unhealthy" ]; then
    echo -e "${YELLOW}⚠ Unhealthy${NC}"
    echo "  Checking logs..."
    docker logs --tail=20 mediavelichie-supabase-studio 2>&1 | tail -5
elif [ "$STUDIO_STATUS" = "no-healthcheck" ]; then
    echo -e "${YELLOW}⚠ No healthcheck configured${NC}"
else
    echo -e "${YELLOW}⚠ Status: $STUDIO_STATUS${NC}"
fi

# Проверка доступности Studio
echo -n "  HTTP availability... "
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:3000/ | grep -q "200\|301\|302\|307"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi
echo ""

# Supabase DB container
echo -n "Supabase DB (mediavelichie-supabase-db)... "
DB_STATUS=$(docker inspect --format='{{.State.Health.Status}}' mediavelichie-supabase-db 2>/dev/null || echo "no-healthcheck")
if [ "$DB_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${YELLOW}⚠ Status: $DB_STATUS${NC}"
fi

# Проверка подключения к БД
echo -n "  Database connection... "
if docker exec mediavelichie-supabase-db pg_isready -U postgres >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ready${NC}"
else
    echo -e "${RED}✗ Not ready${NC}"
fi
echo ""

# Editor container
echo -n "Editor (mediavelichie-editor)... "
EDITOR_STATUS=$(docker inspect --format='{{.State.Health.Status}}' mediavelichie-editor 2>/dev/null || echo "no-healthcheck")
if [ "$EDITOR_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${YELLOW}⚠ Status: $EDITOR_STATUS${NC}"
fi

# Проверка доступности Editor
echo -n "  HTTP availability... "
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:5000/ | grep -q "200"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi
echo ""

# Итоговый отчет
echo "=========================================="
echo -e "${CYAN}Summary${NC}"
echo "=========================================="
echo ""

ALL_HEALTHY=true

if [ "$WEB_STATUS" != "healthy" ]; then
    echo -e "Web: ${YELLOW}⚠ Check healthcheck${NC}"
    ALL_HEALTHY=false
else
    echo -e "Web: ${GREEN}✓ OK${NC}"
fi

if [ "$STUDIO_STATUS" != "healthy" ]; then
    echo -e "Supabase Studio: ${YELLOW}⚠ Check healthcheck${NC}"
    ALL_HEALTHY=false
else
    echo -e "Supabase Studio: ${GREEN}✓ OK${NC}"
fi

if [ "$DB_STATUS" = "healthy" ]; then
    echo -e "Supabase DB: ${GREEN}✓ OK${NC}"
else
    echo -e "Supabase DB: ${YELLOW}⚠ Check${NC}"
    ALL_HEALTHY=false
fi

if [ "$EDITOR_STATUS" = "healthy" ]; then
    echo -e "Editor: ${GREEN}✓ OK${NC}"
else
    echo -e "Editor: ${YELLOW}⚠ Check${NC}"
    ALL_HEALTHY=false
fi

echo ""

# Рекомендации
if [ "$ALL_HEALTHY" = false ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo ""
    
    if [ "$WEB_STATUS" != "healthy" ]; then
        echo "  Web container:"
        echo "    - Check logs: docker logs mediavelichie-web"
        echo "    - Verify Nginx config: docker exec mediavelichie-web nginx -t"
        echo "    - Healthcheck may be too strict, but site is accessible"
    fi
    
    if [ "$STUDIO_STATUS" != "healthy" ]; then
        echo "  Supabase Studio:"
        echo "    - Check logs: docker logs mediavelichie-supabase-studio"
        echo "    - Studio may work even if healthcheck fails"
    fi
    
    echo ""
    echo "Note: 'Unhealthy' status doesn't always mean service is broken."
    echo "If HTTP requests work (200 OK), the service is functional."
fi

echo ""
echo "=========================================="
if [ "$ALL_HEALTHY" = true ]; then
    echo -e "${GREEN}All containers are healthy!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some containers need attention${NC}"
    exit 1
fi
