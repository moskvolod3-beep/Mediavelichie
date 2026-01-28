#!/bin/bash

# Скрипт для автоматического решения проблем с Git и развертывания миграции
# Использование: ./fix-git-and-deploy.sh

set -e

PROJECT_DIR="/opt/mediavelichia"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Исправление Git и развертывание миграции"
echo "=========================================="
echo ""

cd "$PROJECT_DIR" || {
    echo -e "${RED}Ошибка: директория $PROJECT_DIR не существует${NC}"
    exit 1
}

# Шаг 1: Проверка статуса Git
echo "1. Проверка статуса Git..."
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}Обнаружены незакоммиченные изменения${NC}"
    git status --short
    
    echo ""
    echo -e "${YELLOW}Отменяем локальные изменения...${NC}"
    git reset --hard HEAD
    git clean -fd
    echo -e "${GREEN}✓ Локальные изменения отменены${NC}"
else
    echo -e "${GREEN}✓ Нет незакоммиченных изменений${NC}"
fi

# Шаг 2: Обновление кода
echo ""
echo "2. Обновление кода из репозитория..."
if git pull origin main; then
    echo -e "${GREEN}✓ Код обновлен${NC}"
else
    echo -e "${YELLOW}⚠ Конфликт при обновлении, разрешаем...${NC}"
    # Сохраняем текущее состояние
    git stash push -m "Auto-stash before pull $(date)" 2>/dev/null || true
    # Принудительно обновляем
    git fetch origin
    git reset --hard origin/main
    echo -e "${GREEN}✓ Код принудительно обновлен${NC}"
fi

# Шаг 3: Проверка наличия скрипта
echo ""
echo "3. Проверка наличия скрипта deploy-migration.sh..."
if [ -f "deploy-migration.sh" ]; then
    echo -e "${GREEN}✓ Скрипт найден${NC}"
    chmod +x deploy-migration.sh
    echo -e "${GREEN}✓ Скрипт сделан исполняемым${NC}"
else
    echo -e "${RED}✗ Скрипт deploy-migration.sh не найден${NC}"
    echo "Проверьте что git pull выполнился успешно"
    exit 1
fi

# Шаг 4: Проверка наличия файла миграции
echo ""
echo "4. Проверка наличия файла миграции..."
MIGRATION_FILE="backend/supabase/migrations/20260128133013_full_schema_export.sql"
if [ -f "$MIGRATION_FILE" ]; then
    echo -e "${GREEN}✓ Файл миграции найден: $MIGRATION_FILE${NC}"
else
    echo -e "${YELLOW}⚠ Файл миграции не найден, ищем последнюю миграцию...${NC}"
    MIGRATION_FILE=$(ls -t backend/supabase/migrations/*.sql 2>/dev/null | head -1)
    if [ -z "$MIGRATION_FILE" ]; then
        echo -e "${RED}✗ Миграции не найдены${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Найдена миграция: $MIGRATION_FILE${NC}"
fi

# Шаг 5: Информация о следующем шаге
echo ""
echo "=========================================="
echo -e "${GREEN}Подготовка завершена!${NC}"
echo "=========================================="
echo ""
echo "Следующий шаг:"
echo "  Запустите скрипт развертывания:"
echo "    ./deploy-migration.sh"
echo ""
echo "Или примените миграцию вручную:"
echo "    docker exec -i mediavelichie-supabase-db psql -U postgres < $MIGRATION_FILE"
echo ""
