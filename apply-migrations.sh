#!/bin/bash

# Скрипт применения миграций базы данных Supabase
# Использование: ./apply-migrations.sh

set -e

PROJECT_DIR="/opt/mediavelichia"
MIGRATIONS_DIR="$PROJECT_DIR/supabase/migrations"
CONTAINER_NAME="mediavelichie-supabase-db"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Применение миграций базы данных"
echo "=========================================="
echo ""

cd "$PROJECT_DIR" || {
    echo -e "${RED}Ошибка: директория $PROJECT_DIR не существует${NC}"
    exit 1
}

# Проверка существования контейнера
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Ошибка: контейнер $CONTAINER_NAME не запущен${NC}"
    echo "Запустите контейнер: docker compose -f docker-compose.prod.yml up -d supabase"
    exit 1
fi

# Проверка готовности базы данных
echo "Проверка готовности базы данных..."
if ! docker exec "$CONTAINER_NAME" pg_isready -U postgres &> /dev/null; then
    echo -e "${RED}Ошибка: база данных не готова${NC}"
    exit 1
fi

echo -e "${GREEN}✓ База данных готова${NC}"

# Проверка наличия директории с миграциями
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo -e "${YELLOW}⚠ Директория миграций не найдена: $MIGRATIONS_DIR${NC}"
    exit 1
fi

# Получаем список миграций
MIGRATIONS=$(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort)

if [ -z "$MIGRATIONS" ]; then
    echo -e "${YELLOW}⚠ Миграции не найдены в $MIGRATIONS_DIR${NC}"
    exit 0
fi

echo ""
echo "Найдены миграции:"
echo "$MIGRATIONS" | while read migration; do
    echo "  - $(basename "$migration")"
done

echo ""
read -p "Применить все миграции? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено"
    exit 0
fi

# Применяем миграции
echo ""
echo "Применение миграций..."

SUCCESS_COUNT=0
FAIL_COUNT=0

while IFS= read -r migration; do
    MIGRATION_NAME=$(basename "$migration")
    echo ""
    echo "Применение: $MIGRATION_NAME"
    
    if docker exec -i "$CONTAINER_NAME" psql -U postgres < "$migration" 2>&1; then
        echo -e "${GREEN}✓ $MIGRATION_NAME применена успешно${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ Ошибка при применении $MIGRATION_NAME${NC}"
        ((FAIL_COUNT++))
    fi
done <<< "$MIGRATIONS"

# Итоги
echo ""
echo "=========================================="
echo "Итоги применения миграций"
echo "=========================================="
echo -e "${GREEN}Успешно: $SUCCESS_COUNT${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}Ошибок: $FAIL_COUNT${NC}"
fi

if [ $FAIL_COUNT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Все миграции применены успешно!${NC}"
    echo ""
    echo "Проверка таблиц в базе данных:"
    docker exec "$CONTAINER_NAME" psql -U postgres -c "\dt" 2>/dev/null || echo "Не удалось получить список таблиц"
else
    echo ""
    echo -e "${RED}✗ Некоторые миграции не применены${NC}"
    echo "Проверьте логи выше для деталей"
    exit 1
fi

echo ""
