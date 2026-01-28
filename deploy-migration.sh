#!/bin/bash

# Скрипт развертывания миграции на удаленном сервере
# Использование: 
#   ./deploy-migration.sh [путь_к_миграции]  # Автоматическое применение (по умолчанию)
#   CONFIRM=true ./deploy-migration.sh  # С запросом подтверждения

set -e

PROJECT_DIR="${PROJECT_DIR:-/opt/mediavelichia}"
MIGRATIONS_DIR="$PROJECT_DIR/backend/supabase/migrations"
CONTAINER_NAME="mediavelichie-supabase-db"

# Если указан путь к миграции, используем его, иначе применяем последнюю
if [ -n "$1" ]; then
    MIGRATION_FILE="$1"
    if [ ! -f "$MIGRATION_FILE" ]; then
        echo "Ошибка: файл миграции не найден: $MIGRATION_FILE"
        exit 1
    fi
else
    # Находим последнюю миграцию
    MIGRATION_FILE=$(ls -t "$MIGRATIONS_DIR"/*.sql 2>/dev/null | head -1)
    if [ -z "$MIGRATION_FILE" ]; then
        echo "Ошибка: миграции не найдены в $MIGRATIONS_DIR"
        exit 1
    fi
fi

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Развертывание миграции на удаленном сервере"
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
echo ""

# Проверка существования файла миграции
if [ ! -f "$MIGRATION_FILE" ]; then
    echo -e "${RED}Ошибка: файл миграции не найден: $MIGRATION_FILE${NC}"
    exit 1
fi

MIGRATION_NAME=$(basename "$MIGRATION_FILE")
echo -e "${BLUE}Миграция:${NC} $MIGRATION_NAME"
echo ""

# Показываем размер файла
FILE_SIZE=$(du -h "$MIGRATION_FILE" | cut -f1)
echo -e "${BLUE}Размер файла:${NC} $FILE_SIZE"
echo ""

# Предупреждение о применении миграции
echo -e "${YELLOW}⚠ ВНИМАНИЕ:${NC}"
echo "Эта миграция будет применена к базе данных на удаленном сервере."
echo "Убедитесь, что вы:"
echo "  1. Сделали резервную копию базы данных"
echo "  2. Проверили содержимое миграции"
echo "  3. Понимаете последствия применения миграции"
echo ""

# Проверяем флаг подтверждения (по умолчанию применяем автоматически)
if [ "$CONFIRM" = "true" ]; then
    set +e  # Временно отключаем set -e для read
    read -p "Продолжить применение миграции? (y/yes/n/no) " -r REPLY
    set -e  # Включаем обратно
    echo
    
    # Нормализуем ответ: убираем пробелы и приводим к нижнему регистру
    REPLY=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Проверяем ответ
    if [ -z "$REPLY" ] || [ "$REPLY" != "y" ] && [ "$REPLY" != "yes" ]; then
        echo "Отменено"
        exit 0
    fi
else
    echo -e "${BLUE}Применение миграции без подтверждения (используйте CONFIRM=true для запроса подтверждения)${NC}"
fi

# Применение миграции
echo ""
echo "Применение миграции..."
echo ""

# Используем транзакцию для безопасного применения
# Если миграция использует CREATE OR REPLACE, она может быть не в транзакции
# Поэтому применяем напрямую

if docker exec -i "$CONTAINER_NAME" psql -U postgres -v ON_ERROR_STOP=1 < "$MIGRATION_FILE" 2>&1; then
    echo ""
    echo -e "${GREEN}✓ Миграция применена успешно!${NC}"
else
    EXIT_CODE=$?
    echo ""
    echo -e "${RED}✗ Ошибка при применении миграции (код: $EXIT_CODE)${NC}"
    echo ""
    echo "Возможные причины:"
    echo "  - Объекты уже существуют (если миграция не использует IF NOT EXISTS)"
    echo "  - Синтаксическая ошибка в SQL"
    echo "  - Проблемы с правами доступа"
    echo ""
    echo "Проверьте логи выше для деталей"
    exit $EXIT_CODE
fi

# Проверка состояния базы данных после миграции
echo ""
echo "Проверка состояния базы данных..."
echo ""

# Список таблиц
echo -e "${BLUE}Таблицы в базе данных:${NC}"
docker exec "$CONTAINER_NAME" psql -U postgres -c "\dt" 2>/dev/null || echo "Не удалось получить список таблиц"

echo ""
echo -e "${BLUE}Функции в базе данных:${NC}"
docker exec "$CONTAINER_NAME" psql -U postgres -c "\df" 2>/dev/null | head -20 || echo "Не удалось получить список функций"

echo ""
echo "=========================================="
echo -e "${GREEN}Развертывание завершено успешно!${NC}"
echo "=========================================="
echo ""
