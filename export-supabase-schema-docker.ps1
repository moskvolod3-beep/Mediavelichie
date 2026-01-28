# Скрипт экспорта полной схемы базы данных из локального Supabase через Docker (PowerShell)
# Использование: .\export-supabase-schema-docker.ps1

$ErrorActionPreference = "Stop"

# Имя контейнера Supabase (определяем автоматически)
$ContainerName = docker ps --format '{{.Names}}' | Select-String -Pattern 'supabase.*db|supabase_db' | Select-Object -First 1

if (-not $ContainerName) {
    Write-Host "Ошибка: контейнер Supabase не найден" -ForegroundColor Red
    Write-Host "Запущенные контейнеры:" -ForegroundColor Yellow
    docker ps --format '{{.Names}}'
    exit 1
}

$ContainerName = $ContainerName.ToString().Trim()

# Директория для миграций
$MigrationsDir = "backend\supabase\migrations"
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"
$MigrationFile = Join-Path $MigrationsDir "${Timestamp}_full_schema_export.sql"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Экспорт схемы базы данных Supabase" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Контейнер: $ContainerName" -ForegroundColor Blue
Write-Host ""

# Создаем директорию для миграций если её нет
if (-not (Test-Path $MigrationsDir)) {
    New-Item -ItemType Directory -Path $MigrationsDir -Force | Out-Null
}

# Проверка готовности базы данных
Write-Host "Проверка готовности базы данных..."
$readyCheck = docker exec $ContainerName pg_isready -U postgres 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка: база данных не готова" -ForegroundColor Red
    exit 1
}

Write-Host "✓ База данных готова" -ForegroundColor Green
Write-Host ""

# Экспорт полной схемы через Docker
Write-Host "Экспорт схемы базы данных..."
Write-Host "Это может занять некоторое время..."

$dumpOutput = docker exec $ContainerName pg_dump `
    -U postgres `
    -d postgres `
    --schema-only `
    --no-owner `
    --no-privileges `
    --clean `
    --if-exists 2>&1

if ($LASTEXITCODE -eq 0) {
    $dumpOutput | Out-File -FilePath $MigrationFile -Encoding UTF8
    Write-Host "✓ Схема экспортирована успешно" -ForegroundColor Green
} else {
    Write-Host "✗ Ошибка при экспорте схемы" -ForegroundColor Red
    Write-Host $dumpOutput
    exit 1
}

# Добавляем заголовок в начало файла
$ExportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$HeaderLines = @(
    "-- ============================================",
    "-- ПОЛНАЯ МИГРАЦИЯ: Экспорт схемы базы данных",
    "-- ============================================",
    "-- Дата экспорта: $ExportDate",
    "-- Источник: Docker контейнер $ContainerName",
    "-- ",
    "-- Этот файл содержит полную схему базы данных:",
    "--   - Таблицы и их структура",
    "--   - Индексы",
    "--   - Триггеры",
    "--   - Функции и процедуры",
    "--   - Row Level Security (RLS) политики",
    "--   - Последовательности",
    "--   - Пользовательские типы данных",
    "--   - Расширения PostgreSQL",
    "--",
    "-- ВАЖНО: Этот файл использует --clean и --if-exists,",
    "-- поэтому он безопасно удалит существующие объекты перед созданием новых.",
    "-- Используйте с осторожностью на продакшене!",
    "--",
    "-- ============================================",
    ""
)

$Content = Get-Content $MigrationFile -Raw
$Header = $HeaderLines -join "`r`n"
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
