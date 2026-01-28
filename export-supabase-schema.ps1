# Скрипт экспорта полной схемы базы данных из локального Supabase (PowerShell)
# Использование: .\export-supabase-schema.ps1

param(
    [string]$DbHost = "localhost",
    [int]$DbPort = 5432,
    [string]$DbName = "postgres",
    [string]$DbUser = "postgres",
    [string]$DbPassword = "postgres"
)

$ErrorActionPreference = "Stop"

# Директория для миграций
$MigrationsDir = "backend\supabase\migrations"
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"
$MigrationFile = Join-Path $MigrationsDir "${Timestamp}_full_schema_export.sql"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Экспорт схемы базы данных Supabase" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка наличия pg_dump
$pgDumpPath = Get-Command pg_dump -ErrorAction SilentlyContinue
if (-not $pgDumpPath) {
    Write-Host "Ошибка: pg_dump не найден" -ForegroundColor Red
    Write-Host "Установите PostgreSQL client tools из https://www.postgresql.org/download/" -ForegroundColor Yellow
    exit 1
}

# Создаем директорию для миграций если её нет
if (-not (Test-Path $MigrationsDir)) {
    New-Item -ItemType Directory -Path $MigrationsDir -Force | Out-Null
}

# Проверка подключения к базе данных
Write-Host "Проверка подключения к базе данных..."
$env:PGPASSWORD = $DbPassword

try {
    $testQuery = "SELECT 1;" | & psql -h $DbHost -p $DbPort -U $DbUser -d $DbName 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Не удалось подключиться к базе данных"
    }
    Write-Host "✓ Подключение к базе данных установлено" -ForegroundColor Green
} catch {
    Write-Host "Ошибка: не удалось подключиться к базе данных" -ForegroundColor Red
    Write-Host ""
    Write-Host "Проверьте параметры подключения:" -ForegroundColor Yellow
    Write-Host "  Host: $DbHost"
    Write-Host "  Port: $DbPort"
    Write-Host "  Database: $DbName"
    Write-Host "  User: $DbUser"
    Write-Host ""
    Write-Host "Вы можете задать параметры через параметры скрипта:" -ForegroundColor Yellow
    Write-Host "  .\export-supabase-schema.ps1 -DbHost localhost -DbPort 5432 -DbUser postgres -DbPassword your_password"
    exit 1
}

Write-Host ""

# Экспорт полной схемы
Write-Host "Экспорт схемы базы данных..."
Write-Host "Это может занять некоторое время..."

$pgDumpArgs = @(
    "-h", $DbHost
    "-p", $DbPort.ToString()
    "-U", $DbUser
    "-d", $DbName
    "--schema-only"
    "--no-owner"
    "--no-privileges"
    "--clean"
    "--if-exists"
    "--verbose"
)

try {
    & pg_dump $pgDumpArgs | Out-File -FilePath $MigrationFile -Encoding UTF8
    if ($LASTEXITCODE -ne 0) {
        throw "Ошибка при экспорте схемы"
    }
    Write-Host "✓ Схема экспортирована успешно" -ForegroundColor Green
} catch {
    Write-Host "✗ Ошибка при экспорте схемы" -ForegroundColor Red
    exit 1
}

# Добавляем заголовок в начало файла
$Header = @"
-- ============================================
-- ПОЛНАЯ МИГРАЦИЯ: Экспорт схемы базы данных
-- ============================================
-- Дата экспорта: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
-- Источник: ${DbHost}:${DbPort}/${DbName}
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

$Content = Get-Content $MigrationFile -Raw
$NewContent = $Header + $Content
Set-Content -Path $MigrationFile -Value $NewContent -Encoding UTF8

# Статистика
$TablesCount = (Select-String -Path $MigrationFile -Pattern "^CREATE TABLE" -AllMatches).Matches.Count
$FunctionsCount = (Select-String -Path $MigrationFile -Pattern "^CREATE FUNCTION|^CREATE OR REPLACE FUNCTION" -AllMatches).Matches.Count
$TriggersCount = (Select-String -Path $MigrationFile -Pattern "^CREATE TRIGGER" -AllMatches).Matches.Count
$PoliciesCount = (Select-String -Path $MigrationFile -Pattern "^CREATE POLICY" -AllMatches).Matches.Count

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Экспорт завершен!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Файл миграции: $MigrationFile" -ForegroundColor Blue
Write-Host ""
Write-Host "Статистика:" -ForegroundColor Blue
Write-Host "  Таблиц: $TablesCount"
Write-Host "  Функций: $FunctionsCount"
Write-Host "  Триггеров: $TriggersCount"
Write-Host "  RLS политик: $PoliciesCount"
Write-Host ""
Write-Host "✓ Миграция готова к коммиту" -ForegroundColor Green
Write-Host ""
Write-Host "Следующие шаги:" -ForegroundColor Yellow
Write-Host "  1. Проверьте файл миграции: Get-Content $MigrationFile"
Write-Host "  2. Закоммитьте изменения: git add $MigrationFile; git commit -m 'Add full schema migration'"
Write-Host "  3. Примените на удаленном сервере используя скрипт deploy-migration.sh"
Write-Host ""

# Очищаем пароль из переменных окружения
Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
