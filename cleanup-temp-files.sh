#!/bin/bash

# Скрипт для очистки временных файлов и возврата к исходной архитектуре

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Cleanup Temporary Files${NC}"
echo "=========================================="
echo ""

cd /opt/mediavelichia

# Список временных файлов для удаления
TEMP_FILES=(
    # Studio/pg-meta скрипты
    "apply-studio-fix.sh"
    "check-available-images.sh"
    "check-studio-logs.sh"
    "fix-pg-meta-host.sh"
    "fix-pg-meta-user.sh"
    "fix-supabase-studio-connection.sh"
    "switch-to-pgadmin.sh"
    "update-and-check-studio.sh"
    "quick-fix-and-setup.sh"
    # Конфигурации
    "docker-compose.prod-simple.yml"
    # Документация по Studio
    "FIX_STUDIO_ERROR.md"
    "FIX_STORAGE_ERROR.md"
    "FIX_STUDIO_IMAGES.md"
    "FIX_SUPABASE_STUDIO.md"
    "STUDIO_CONNECTION_GUIDE.md"
    "QUICK_STUDIO_CONNECTION.md"
    "UPDATE_STUDIO_CONFIG.md"
)

echo -e "${BLUE}Removing temporary files...${NC}"
for FILE in "${TEMP_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        rm -f "$FILE"
        echo "  Removed: $FILE"
    fi
done

echo ""
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Останавливаем ненужные контейнеры
echo -e "${BLUE}Stopping unnecessary containers...${NC}"
docker compose -f docker-compose.prod.yml stop supabase-studio supabase-meta 2>/dev/null || true
docker compose -f docker-compose.prod.yml rm -f supabase-studio supabase-meta 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

echo "=========================================="
echo -e "${CYAN}Cleanup Complete${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Current architecture:${NC}"
echo "  - web (Nginx frontend)"
echo "  - supabase (PostgreSQL database)"
echo "  - editor (Flask backend)"
echo ""
echo -e "${BLUE}To restart services:${NC}"
echo "  docker compose -f docker-compose.prod.yml up -d"
echo ""
