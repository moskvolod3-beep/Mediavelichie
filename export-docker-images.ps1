# PowerShell скрипт для экспорта Docker образов
# Использование: .\export-docker-images.ps1

# Не останавливаем выполнение при ошибках команд docker
$ErrorActionPreference = "Continue"

$EXPORT_DIR = ".\docker-images-export"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Exporting Docker images for server transfer" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""

# Create export directory
if (-not (Test-Path $EXPORT_DIR)) {
    New-Item -ItemType Directory -Path $EXPORT_DIR | Out-Null
}

# List of images to export (only custom images - Supabase will be pulled on server)
$IMAGES = @(
    "mediavelichia-web:latest",
    "mediavelichia-editor:latest"
)

Write-Host "Searching for local images..." -ForegroundColor Blue
Write-Host ""

# Собираем образы если они еще не собраны
Write-Host "Building images from docker-compose.prod.yml..." -ForegroundColor Blue
docker compose -f docker-compose.prod.yml build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Build completed with errors. Continuing anyway..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Exporting images..." -ForegroundColor Blue
Write-Host ""

$EXPORTED_FILES = @()

foreach ($IMAGE in $IMAGES) {
    # Проверяем существует ли образ (подавляем ошибки)
    $checkResult = docker image inspect $IMAGE 2>&1
    $imageExists = $LASTEXITCODE -eq 0
    
    if ($imageExists) {
        Write-Host "Found image: $IMAGE" -ForegroundColor Green
        
        # Создаем имя файла из имени образа
        $FILENAME = $IMAGE -replace '[/:]', '_'
        $EXPORT_FILE = Join-Path $EXPORT_DIR "$FILENAME.tar"
        
        Write-Host "  Exporting to: $EXPORT_FILE"
        docker save $IMAGE -o $EXPORT_FILE
        
        if ($LASTEXITCODE -eq 0) {
            # Сжимаем файл (используем 7zip или gzip если доступен)
            Write-Host "  Compressing..."
            
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
            Write-Host "  OK! Size: $([math]::Round($FILE_SIZE, 2)) MB" -ForegroundColor Green
            Write-Host ""
        }
    } else {
        Write-Host "Image not found: $IMAGE (skipping)" -ForegroundColor Yellow
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
echo "Importing Docker Images"
echo "=========================================="
echo ""

# Импортируем все .tar.gz файлы
for FILE in *.tar.gz; do
    if [ -f "\$FILE" ]; then
        echo -e "\${BLUE}Importing:\${NC} \$FILE"
        gunzip -c "\$FILE" | docker load
        if [ \$? -eq 0 ]; then
            echo -e "\${GREEN}✓\${NC} Image imported: \$FILE"
        else
            echo -e "\${RED}✗\${NC} Failed to import: \$FILE"
        fi
        echo ""
    fi
done 2>/dev/null || true

# Импортируем все .tar.zip файлы
for FILE in *.tar.zip; do
    if [ -f "\$FILE" ]; then
        echo -e "\${BLUE}Importing:\${NC} \$FILE"
        unzip -p "\$FILE" | docker load
        if [ \$? -eq 0 ]; then
            echo -e "\${GREEN}✓\${NC} Image imported: \$FILE"
        else
            echo -e "\${RED}✗\${NC} Failed to import: \$FILE"
        fi
        echo ""
    fi
done 2>/dev/null || true

# Импортируем все .tar файлы (без сжатия)
for FILE in *.tar; do
    # Пропускаем .tar.gz и .tar.zip (уже обработаны)
    if [[ "\$FILE" != *.gz ]] && [[ "\$FILE" != *.zip ]]; then
        if [ -f "\$FILE" ]; then
            echo -e "\${BLUE}Importing:\${NC} \$FILE"
            docker load -i "\$FILE"
            if [ \$? -eq 0 ]; then
                echo -e "\${GREEN}✓\${NC} Image imported: \$FILE"
            else
                echo -e "\${RED}✗\${NC} Failed to import: \$FILE"
            fi
            echo ""
        fi
    fi
done 2>/dev/null || true

echo "=========================================="
echo -e "\${GREEN}Import completed!\${NC}"
echo "=========================================="
echo ""
echo "Checking imported images:"
docker images | grep -E "mediavelichia|REPOSITORY" || echo "No custom images found"
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

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Export completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Exported files:" -ForegroundColor Blue
$EXPORTED_FILES | ForEach-Object {
    $FILE_SIZE = [math]::Round((Get-Item $_).Length / 1MB, 2)
    $FILENAME = Split-Path $_ -Leaf
    Write-Host "  - $FILENAME ($FILE_SIZE MB)"
}

$TOTAL_SIZE = [math]::Round((Get-ChildItem $EXPORT_DIR -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
Write-Host ""
Write-Host "Total size: $TOTAL_SIZE MB" -ForegroundColor Blue
Write-Host ""
Write-Host "Export directory: $EXPORT_DIR" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Transfer contents of '$EXPORT_DIR' directory to server"
Write-Host "  2. On server run: cd /opt/mediavelichia/docker-images-import && ./import-images.sh"
Write-Host ""
