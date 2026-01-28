#!/bin/bash

# Скрипт для исправления кодировки файла миграции
# Конвертирует UTF-16 в UTF-8

set -e

MIGRATION_FILE="${1:-backend/supabase/migrations/20260128133013_full_schema_export.sql}"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "Ошибка: файл миграции не найден: $MIGRATION_FILE"
    exit 1
fi

echo "Исправление кодировки файла: $MIGRATION_FILE"

# Создаем резервную копию
BACKUP_FILE="${MIGRATION_FILE}.backup"
cp "$MIGRATION_FILE" "$BACKUP_FILE"
echo "Создана резервная копия: $BACKUP_FILE"

# Конвертируем UTF-16 LE в UTF-8
# Используем iconv или recode, если доступны
if command -v iconv &> /dev/null; then
    iconv -f UTF-16LE -t UTF-8 "$MIGRATION_FILE" > "${MIGRATION_FILE}.tmp" && mv "${MIGRATION_FILE}.tmp" "$MIGRATION_FILE"
    echo "✓ Файл конвертирован в UTF-8 с помощью iconv"
elif command -v recode &> /dev/null; then
    recode UTF-16LE..UTF-8 "$MIGRATION_FILE"
    echo "✓ Файл конвертирован в UTF-8 с помощью recode"
else
    echo "Ошибка: не найдены инструменты iconv или recode"
    echo "Установите один из них:"
    echo "  Ubuntu/Debian: sudo apt-get install recode"
    echo "  или используйте Python скрипт fix-migration-encoding.py"
    exit 1
fi

echo "Готово! Файл миграции теперь в кодировке UTF-8"
