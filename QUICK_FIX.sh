#!/bin/bash

# Быстрое решение проблемы с клонированием репозитория
# Использование: ./QUICK_FIX.sh

set -e

PROJECT_DIR="/opt/mediavelichia"
REPO_URL="https://github.com/moskvolod3-beep/Mediavelichie.git"

echo "=========================================="
echo "Исправление проблемы с клонированием"
echo "=========================================="
echo ""

# Проверяем, существует ли директория
if [ -d "$PROJECT_DIR" ]; then
    echo "Директория $PROJECT_DIR существует"
    
    # Проверяем, является ли она Git репозиторием
    if [ -d "$PROJECT_DIR/.git" ]; then
        echo "✓ Git репозиторий уже инициализирован"
        echo "Обновляем код..."
        cd "$PROJECT_DIR"
        git fetch origin
        git reset --hard origin/main
    else
        echo "Директория существует, но не является Git репозиторием"
        echo "Инициализируем Git..."
        
        # Сохраняем .env если существует
        if [ -f "$PROJECT_DIR/.env" ]; then
            echo "Сохраняем .env файл..."
            cp "$PROJECT_DIR/.env" /tmp/.env.backup
        fi
        
        cd "$PROJECT_DIR"
        git init
        git remote add origin "$REPO_URL" || git remote set-url origin "$REPO_URL"
        git fetch origin
        git checkout -b main origin/main
        
        # Восстанавливаем .env
        if [ -f /tmp/.env.backup ]; then
            echo "Восстанавливаем .env файл..."
            cp /tmp/.env.backup "$PROJECT_DIR/.env"
        fi
    fi
else
    echo "Директория не существует, клонируем репозиторий..."
    cd /opt
    git clone "$REPO_URL" mediavelichia
fi

echo ""
echo "=========================================="
echo "Проверка результата"
echo "=========================================="
cd "$PROJECT_DIR"
echo "Текущая директория: $(pwd)"
echo "Git статус:"
git status --short || echo "Git не инициализирован"
echo ""
echo "Файлы в директории:"
ls -lah | head -10
echo ""
echo "=========================================="
echo "Готово!"
echo "=========================================="
echo ""
echo "Следующие шаги:"
echo "1. Проверьте файл .env: ls -la $PROJECT_DIR/.env"
echo "2. Если .env отсутствует, создайте: cp .env.example .env && nano .env"
echo "3. Запустите контейнеры: docker compose -f docker-compose.prod.cloud.yml up -d --build"
