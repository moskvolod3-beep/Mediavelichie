#!/bin/bash

# Скрипт экспорта полной схемы базы данных из локального Supabase
# Использование: ./export-supabase-schema.sh

set -e

# Настройки подключения к локальному Supabase
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

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

# Проверка наличия pg_dump
if ! command -v pg_dump &> /dev/null; then
    echo -e "${RED}Ошибка: pg_dump не найден${NC}"
    echo "Установите PostgreSQL client tools:"
    echo "  Ubuntu/Debian: sudo apt install postgresql-client"
    echo "  macOS: brew install postgresql"
    echo "  Windows: установите PostgreSQL из https://www.postgresql.org/download/"
    exit 1
fi

# Создаем директорию для миграций если её нет
mkdir -p "$MIGRATIONS_DIR"

# Проверка подключения к базе данных
echo "Проверка подключения к базе данных..."
export PGPASSWORD="$DB_PASSWORD"
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
    echo -e "${RED}Ошибка: не удалось подключиться к базе данных${NC}"
    echo ""
    echo "Проверьте параметры подключения:"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo ""
    echo "Вы можете задать параметры через переменные окружения:"
    echo "  DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=your_password ./export-supabase-schema.sh"
    exit 1
fi

echo -e "${GREEN}✓ Подключение к базе данных установлено${NC}"
echo ""

# Экспорт полной схемы (без данных)
echo "Экспорт схемы базы данных..."
echo "Это может занять некоторое время..."

# Экспортируем схему с:
# - CREATE TABLE statements
# - Индексы
# - Триггеры
# - Функции
# - RLS политики
# - Последовательности
# - Типы данных
# - Расширения (extensions)

pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --schema-only \
    --no-owner \
    --no-privileges \
    --clean \
    --if-exists \
    --verbose \
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
-- Источник: $DB_HOST:$DB_PORT/$DB_NAME
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

# Очищаем пароль из переменных окружения
unset PGPASSWORD
