# Простой скрипт для добавления заголовка к файлу миграции
param(
    [string]$MigrationFile = "backend\supabase\migrations\20260128133013_full_schema_export.sql"
)

$ErrorActionPreference = "Stop"

$ExportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$ContainerName = "supabase_db_Mediavelichia"

$Header = @"
-- ============================================
-- ПОЛНАЯ МИГРАЦИЯ: Экспорт схемы базы данных
-- ============================================
-- Дата экспорта: $ExportDate
-- Источник: Docker контейнер $ContainerName
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

"@

# Читаем файл как UTF-8 без BOM
$Content = [System.IO.File]::ReadAllText($MigrationFile, [System.Text.Encoding]::UTF8)

# Добавляем заголовок
$NewContent = $Header + $Content

# Сохраняем как UTF-8 без BOM
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($MigrationFile, $NewContent, $Utf8NoBom)

Write-Host "Заголовок добавлен к файлу: $MigrationFile" -ForegroundColor Green
