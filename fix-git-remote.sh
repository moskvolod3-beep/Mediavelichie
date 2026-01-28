#!/bin/bash

# Скрипт для исправления Git remote на сервере
# Использование: ./fix-git-remote.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=========================================="
echo -e "${CYAN}Fixing Git Remote Configuration${NC}"
echo "=========================================="
echo ""

# Проверяем текущие remotes
echo -e "${BLUE}Current Git remotes:${NC}"
git remote -v
echo ""

# Проверяем, существует ли remote 'github'
if git remote get-url github >/dev/null 2>&1; then
    echo -e "${GREEN}Remote 'github' exists${NC}"
    GITHUB_URL=$(git remote get-url github)
    echo "URL: $GITHUB_URL"
    echo ""
else
    echo -e "${YELLOW}Remote 'github' not found. Checking 'origin'...${NC}"
    
    if git remote get-url origin >/dev/null 2>&1; then
        ORIGIN_URL=$(git remote get-url origin)
        echo "Origin URL: $ORIGIN_URL"
        echo ""
        
        # Если origin указывает на GitHub, создаем alias 'github'
        if [[ "$ORIGIN_URL" == *"github.com"* ]] || [[ "$ORIGIN_URL" == *"github"* ]]; then
            echo -e "${BLUE}Adding 'github' as alias for 'origin'...${NC}"
            git remote add github "$ORIGIN_URL" 2>/dev/null || git remote set-url github "$ORIGIN_URL"
            echo -e "${GREEN}✓${NC} Remote 'github' added"
        else
            echo -e "${YELLOW}Origin doesn't point to GitHub. Adding GitHub remote...${NC}"
            echo "Please provide GitHub repository URL:"
            echo "Example: https://github.com/username/repo.git"
            read -p "GitHub URL: " GITHUB_REPO_URL
            
            if [ -n "$GITHUB_REPO_URL" ]; then
                git remote add github "$GITHUB_REPO_URL" 2>/dev/null || git remote set-url github "$GITHUB_REPO_URL"
                echo -e "${GREEN}✓${NC} Remote 'github' added"
            else
                echo -e "${RED}No URL provided. Exiting.${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${RED}No Git remotes found!${NC}"
        echo "Please initialize Git repository or add a remote manually."
        exit 1
    fi
    echo ""
fi

# Проверяем финальную конфигурацию
echo -e "${BLUE}Final Git remotes:${NC}"
git remote -v
echo ""

# Тестируем подключение
echo -e "${BLUE}Testing connection to 'github' remote...${NC}"
if git ls-remote github >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Connection successful!"
    echo ""
    echo -e "${CYAN}You can now use:${NC}"
    echo "  git pull github main"
    echo "  git fetch github"
else
    echo -e "${RED}✗${NC} Connection failed!"
    echo "Please check your SSH keys or repository access."
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Git remote configuration fixed!${NC}"
echo "=========================================="
