#!/bin/bash

# Скрипт экспорта полной схемы базы данных из локального Supabase через Docker
# Использование: ./export-supabase-schema-docker.sh

set -e

# Имя контейнера Supabase (определяем автоматически)
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E 'supabase.*db|supabase_db' | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "Ошибка: контейнер Supabase не найден"
    echo "Запущенные контейнеры:"
    docker ps --format '{{.Names}}'
    exit 1
fi

# Директория для миграций
MIGRATIONS_DIR="backend/supabase/migrations"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
MIGRATION_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_full_schema_export.sql"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Экспорт схемы базы данных Supabase"
echo "=========================================="
echo ""
echo "Контейнер: $CONTAINER_NAME"
echo ""

# Создаем директорию для миграций если её нет
mkdir -p "$MIGRATIONS_DIR"

# Проверка готовности базы данных
echo "Проверка готовности базы данных..."
if ! docker exec "$CONTAINER_NAME" pg_isready -U postgres &> /dev/null; then
    echo -e "${RED}Ошибка: база данных не готова${NC}"
    exit 1
fi

echo -e "${GREEN}✓ База данных готова${NC}"
echo ""

# Экспорт полной схемы через Docker
echo "Экспорт схемы базы данных..."
echo "Это может занять некоторое время..."

docker exec "$CONTAINER_NAME" pg_dump \
    -U postgres \
    -d postgres \
    --schema-only \
    --no-owner \
    --no-privileges \
    --clean \
    --if-exists \
    > "$MIGRATION_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Схема экспортирована успешно${NC}"
else
    echo -e "${RED}✗ Ошибка при экспорте схемы${NC}"
    exit 1
fi

# Добавляем заголовок в начало файла
HEADER="-- ============================================
-- ПОЛНАЯ МИГРАЦИЯ: Экспорт схемы базы данных
-- ============================================
-- Дата экспорта: $(date '+%Y-%m-%d %H:%M:%S')
-- Источник: Docker контейнер $CONTAINER_NAME
-- 
-- Этот файл содержит полную схему базы данных:
--   - Таблицы и их структура
--   - Индексы
--   - Триггеры
--   - Функции и процедуры
--   - Row Level Security (RLS) политики
--   - Последовательности
--   - Пользовательские типы данных
--   - Расширения PostgreSQL
--
-- ВАЖНО: Этот файл использует --clean и --if-exists,
-- поэтому он безопасно удалит существующие объекты перед созданием новых.
-- Используйте с осторожностью на продакшене!
--
-- ============================================

"

# Добавляем заголовок в начало файла
echo -e "$HEADER$(cat "$MIGRATION_FILE")" > "$MIGRATION_FILE.tmp"
mv "$MIGRATION_FILE.tmp" "$MIGRATION_FILE"

# Статистика
TABLES_COUNT=$(grep -c "^CREATE TABLE" "$MIGRATION_FILE" || echo "0")
FUNCTIONS_COUNT=$(grep -c "^CREATE FUNCTION\|^CREATE OR REPLACE FUNCTION" "$MIGRATION_FILE" || echo "0")
TRIGGERS_COUNT=$(grep -c "^CREATE TRIGGER" "$MIGRATION_FILE" || echo "0")
POLICIES_COUNT=$(grep -c "^CREATE POLICY" "$MIGRATION_FILE" || echo "0")

echo ""
echo "=========================================="
echo "Экспорт завершен!"
echo "=========================================="
echo ""
echo -e "${BLUE}Файл миграции:${NC} $MIGRATION_FILE"
echo ""
echo -e "${BLUE}Статистика:${NC}"
echo "  Таблиц: $TABLES_COUNT"
echo "  Функций: $FUNCTIONS_COUNT"
echo "  Триггеров: $TRIGGERS_COUNT"
echo "  RLS политик: $POLICIES_COUNT"
echo ""
echo -e "${GREEN}✓ Миграция готова к коммиту${NC}"
echo ""
echo "Следующие шаги:"
echo "  1. Проверьте файл миграции: cat $MIGRATION_FILE"
echo "  2. Закоммитьте изменения: git add $MIGRATION_FILE && git commit -m 'Add full schema migration'"
echo "  3. Примените на удаленном сервере используя скрипт deploy-migration.sh"
echo ""
