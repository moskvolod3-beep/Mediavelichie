# PowerShell скрипт для экспорта Docker образов
# Использование: .\export-docker-images.ps1

$ErrorActionPreference = "Stop"

$EXPORT_DIR = ".\docker-images-export"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Экспорт Docker образов для переноса на сервер" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Создаем директорию для экспорта
if (-not (Test-Path $EXPORT_DIR)) {
    New-Item -ItemType Directory -Path $EXPORT_DIR | Out-Null
}

# Список образов для экспорта
$IMAGES = @(
    "mediavelichie-web:latest",
    "mediavelichie-editor:latest",
    "supabase/postgres:15.1.0.117",
    "supabase/studio:latest"
)

Write-Host "Поиск локальных образов..." -ForegroundColor Blue
Write-Host ""

# Собираем образы если они еще не собраны
Write-Host "Сборка образов из docker-compose.prod.yml..." -ForegroundColor Blue
docker compose -f docker-compose.prod.yml build --quiet

Write-Host ""
Write-Host "Экспорт образов..." -ForegroundColor Blue
Write-Host ""

$EXPORTED_FILES = @()

foreach ($IMAGE in $IMAGES) {
    # Проверяем существует ли образ
    $imageExists = docker image inspect $IMAGE 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Найден образ: $IMAGE" -ForegroundColor Green
        
        # Создаем имя файла из имени образа
        $FILENAME = $IMAGE -replace '[/:]', '_'
        $EXPORT_FILE = Join-Path $EXPORT_DIR "$FILENAME.tar"
        
        Write-Host "  Экспорт в: $EXPORT_FILE"
        docker save $IMAGE -o $EXPORT_FILE
        
        if ($LASTEXITCODE -eq 0) {
            # Сжимаем файл (используем 7zip или gzip если доступен)
            Write-Host "  Сжатие..."
            
            # Пробуем использовать gzip через WSL или Git Bash
            $gzipAvailable = Get-Command gzip -ErrorAction SilentlyContinue
            if ($gzipAvailable) {
                gzip -f $EXPORT_FILE
                $EXPORT_FILE = "$EXPORT_FILE.gz"
            } else {
                # Используем PowerShell Compress-Archive (создает .zip)
                $ZIP_FILE = "$EXPORT_FILE.zip"
                Compress-Archive -Path $EXPORT_FILE -DestinationPath $ZIP_FILE -Force
                Remove-Item $EXPORT_FILE
                $EXPORT_FILE = $ZIP_FILE
            }
            
            $EXPORTED_FILES += $EXPORT_FILE
            
            $FILE_SIZE = (Get-Item $EXPORT_FILE).Length / 1MB
            Write-Host "  ✓ Готово! Размер: $([math]::Round($FILE_SIZE, 2)) MB" -ForegroundColor Green
            Write-Host ""
        }
    } else {
        Write-Host "⚠ Образ не найден: $IMAGE (пропускаем)" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Создаем скрипт для импорта на сервере
$IMPORT_SCRIPT = Join-Path $EXPORT_DIR "import-images.sh"
@"
#!/bin/bash

# Скрипт для импорта Docker образов на сервере
# Использование: ./import-images.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Импорт Docker образов"
echo "=========================================="
echo ""

# Импортируем все .tar.gz и .tar.zip файлы
for FILE in *.tar.gz *.tar.zip 2>/dev/null; do
    if [ -f "\$FILE" ]; then
        echo -e "\${BLUE}Импорт:\${NC} \$FILE"
        
        # Распаковываем и импортируем
        if [[ "\$FILE" == *.gz ]]; then
            gunzip -c "\$FILE" | docker load
        elif [[ "\$FILE" == *.zip ]]; then
            unzip -p "\$FILE" | docker load
        fi
        
        echo -e "\${GREEN}✓\${NC} Образ импортирован: \$FILE"
        echo ""
    fi
done

echo "=========================================="
echo -e "\${GREEN}Импорт завершен!\${NC}"
echo "=========================================="
echo ""
echo "Проверка импортированных образов:"
docker images | grep -E "mediavelichie|supabase" || echo "Образы не найдены"
"@ | Out-File -FilePath $IMPORT_SCRIPT -Encoding UTF8

# Создаем README с инструкциями
$README_FILE = Join-Path $EXPORT_DIR "README.md"
$README_CONTENT = @"
# Экспорт Docker образов

Дата экспорта: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Экспортированные образы

$($EXPORTED_FILES | ForEach-Object { "- ``$(Split-Path $_ -Leaf)`` ($([math]::Round((Get-Item $_).Length / 1MB, 2)) MB)" })

## Инструкция по переносу на сервер

### 1. Передача файлов на сервер

\`\`\`bash
# С локального компьютера (Windows PowerShell или Git Bash)
scp -r docker-images-export/* user@your-server-ip:/opt/mediavelichia/docker-images-import/

# Или используйте WinSCP / FileZilla для графического интерфейса
\`\`\`

### 2. Импорт образов на сервере

\`\`\`bash
# На сервере
cd /opt/mediavelichia/docker-images-import

# Сделайте скрипт исполняемым
chmod +x import-images.sh

# Запустите импорт
./import-images.sh
\`\`\`

### 3. Проверка импортированных образов

\`\`\`bash
docker images | grep -E "mediavelichie|supabase"
\`\`\`

### 4. Запуск контейнеров

После импорта образов запустите контейнеры:

\`\`\`bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml up -d
\`\`\`

## Размеры файлов

$($EXPORTED_FILES | ForEach-Object { "- ``$(Split-Path $_ -Leaf)``: $([math]::Round((Get-Item $_).Length / 1MB, 2)) MB" })

**Общий размер:** $([math]::Round((Get-ChildItem $EXPORT_DIR -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB
"@

$README_CONTENT | Out-File -FilePath $README_FILE -Encoding UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Экспорт завершен!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Экспортированные файлы:" -ForegroundColor Blue
$EXPORTED_FILES | ForEach-Object {
    $FILE_SIZE = [math]::Round((Get-Item $_).Length / 1MB, 2)
    Write-Host "  - $(Split-Path $_ -Leaf) ($FILE_SIZE MB)"
}

$TOTAL_SIZE = [math]::Round((Get-ChildItem $EXPORT_DIR -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
Write-Host ""
Write-Host "Общий размер: $TOTAL_SIZE MB" -ForegroundColor Blue
Write-Host ""
Write-Host "Директория экспорта: $EXPORT_DIR" -ForegroundColor Blue
Write-Host ""
Write-Host "Следующие шаги:"
Write-Host "  1. Передайте содержимое директории '$EXPORT_DIR' на сервер"
Write-Host "  2. На сервере выполните: cd /opt/mediavelichia/docker-images-import && ./import-images.sh"
Write-Host ""
