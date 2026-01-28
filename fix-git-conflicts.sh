#!/bin/bash

# Скрипт для разрешения Git конфликтов на сервере
# Использование: ./fix-git-conflicts.sh [--keep-local|--use-remote|--stash]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="/opt/mediavelichia"

echo "=========================================="
echo -e "${CYAN}Git Conflict Resolution${NC}"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Проверяем статус Git
echo -e "${BLUE}Checking Git status...${NC}"
git status --short
echo ""

# Определяем стратегию разрешения конфликтов
STRATEGY="${1:-use-remote}"

case "$STRATEGY" in
    --keep-local)
        echo -e "${YELLOW}Strategy: Keep local changes${NC}"
        echo "Stashing local changes..."
        git stash push -m "Local changes saved before pull $(date)"
        git pull origin main
        echo -e "${GREEN}✓${NC} Pull completed. Local changes saved in stash."
        echo "To restore: git stash pop"
        ;;
    --use-remote)
        echo -e "${YELLOW}Strategy: Use remote changes (discard local)${NC}"
        echo "Discarding local changes..."
        git reset --hard HEAD
        git clean -fd
        git pull origin main
        echo -e "${GREEN}✓${NC} Pull completed. Local changes discarded."
        ;;
    --stash)
        echo -e "${YELLOW}Strategy: Stash and pull${NC}"
        echo "Stashing changes..."
        git stash push -m "Auto-stash before pull $(date)"
        git pull origin main
        echo -e "${GREEN}✓${NC} Pull completed. Changes stashed."
        echo "To restore: git stash pop"
        ;;
    *)
        echo -e "${RED}Unknown strategy: $STRATEGY${NC}"
        echo ""
        echo "Usage: ./fix-git-conflicts.sh [--keep-local|--use-remote|--stash]"
        echo ""
        echo "Strategies:"
        echo "  --keep-local  : Save local changes in stash, then pull"
        echo "  --use-remote  : Discard local changes, use remote version (default)"
        echo "  --stash       : Same as --keep-local"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo -e "${GREEN}Git conflicts resolved!${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}Current status:${NC}"
git status --short
echo ""
