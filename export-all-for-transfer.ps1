# PowerShell скрипт для полного экспорта контейнеров и данных Supabase
# Экспортирует: Docker образы, данные БД (таблицы), Storage данные
# Использование: .\export-all-for-transfer.ps1

$ErrorActionPreference = "Continue"

$EXPORT_DIR = ".\docker-images-export"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Full Export: Docker Images + Supabase Data" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Создаем директорию экспорта
if (-not (Test-Path $EXPORT_DIR)) {
    New-Item -ItemType Directory -Path $EXPORT_DIR | Out-Null
    Write-Host "Created export directory: $EXPORT_DIR" -ForegroundColor Green
}

# Создаем поддиректории
$DB_EXPORT_DIR = Join-Path $EXPORT_DIR "database"
$STORAGE_EXPORT_DIR = Join-Path $EXPORT_DIR "storage"
$IMAGES_EXPORT_DIR = Join-Path $EXPORT_DIR "images"

foreach ($dir in @($DB_EXPORT_DIR, $STORAGE_EXPORT_DIR, $IMAGES_EXPORT_DIR)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

Write-Host ""

# ============================================
# ШАГ 1: Сборка Docker образов
# ============================================
Write-Host "Step 1: Building Docker images..." -ForegroundColor Blue
Write-Host ""

docker compose -f docker-compose.prod.yml build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Build completed with errors. Continuing anyway..." -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# ШАГ 2: Экспорт Docker образов
# ============================================
Write-Host "Step 2: Exporting Docker images..." -ForegroundColor Blue
Write-Host ""

$IMAGES = @(
    "mediavelichia-web:latest",
    "mediavelichia-editor:latest"
)

$EXPORTED_IMAGES = @()

foreach ($IMAGE in $IMAGES) {
    $checkResult = docker image inspect $IMAGE 2>&1
    $imageExists = $LASTEXITCODE -eq 0
    
    if ($imageExists) {
        Write-Host "Found image: $IMAGE" -ForegroundColor Green
        
        $FILENAME = $IMAGE -replace '[/:]', '_'
        $EXPORT_FILE = Join-Path $IMAGES_EXPORT_DIR "$FILENAME.tar"
        
        Write-Host "  Exporting to: $EXPORT_FILE"
        docker save $IMAGE -o $EXPORT_FILE
        
        if ($LASTEXITCODE -eq 0) {
            # Сжимаем файл
            Write-Host "  Compressing..."
            
            $gzipAvailable = $false
            # Пробуем WSL gzip
            if (Get-Command wsl -ErrorAction SilentlyContinue) {
                $wslGzipCheck = wsl which gzip 2>$null
                if ($LASTEXITCODE -eq 0) {
                    wsl gzip -f $(wsl wslpath -a $EXPORT_FILE)
                    if ($LASTEXITCODE -eq 0) {
                        $EXPORT_FILE = "$EXPORT_FILE.gz"
                        $gzipAvailable = $true
                    }
                }
            }
            
            # Пробуем Git Bash gzip
            if (-not $gzipAvailable -and (Test-Path "C:\Program Files\Git\usr\bin\gzip.exe")) {
                & "C:\Program Files\Git\usr\bin\gzip.exe" -f $EXPORT_FILE
                if ($LASTEXITCODE -eq 0) {
                    $EXPORT_FILE = "$EXPORT_FILE.gz"
                    $gzipAvailable = $true
                }
            }
            
            # Fallback на ZIP
            if (-not $gzipAvailable) {
                $ZIP_FILE = "$EXPORT_FILE.zip"
                Compress-Archive -Path $EXPORT_FILE -DestinationPath $ZIP_FILE -Force
                Remove-Item $EXPORT_FILE
                $EXPORT_FILE = $ZIP_FILE
            }
            
            $EXPORTED_IMAGES += $EXPORT_FILE
            $FILE_SIZE = [math]::Round((Get-Item $EXPORT_FILE).Length / 1MB, 2)
            Write-Host "  OK! Size: $FILE_SIZE MB" -ForegroundColor Green
            Write-Host ""
        }
    } else {
        Write-Host "Image not found: $IMAGE (skipping)" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ============================================
# ШАГ 3: Экспорт данных БД (таблицы)
# ============================================
Write-Host "Step 3: Exporting database (tables)..." -ForegroundColor Blue
Write-Host ""

# Проверяем запущен ли контейнер Supabase
$SUPABASE_CONTAINER = "mediavelichie-supabase-db"
$containerRunning = docker ps --format "{{.Names}}" | Select-String -Pattern $SUPABASE_CONTAINER

if ($containerRunning) {
    Write-Host "Supabase container is running: $SUPABASE_CONTAINER" -ForegroundColor Green
    
    # Получаем пароль из .env
    $POSTGRES_PASSWORD = ""
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" | Where-Object { $_ -match "^POSTGRES_PASSWORD=" }
        if ($envContent) {
            $POSTGRES_PASSWORD = ($envContent -split "=")[1].Trim() -replace '"', '' -replace "'", ''
        }
    }
    
    if ([string]::IsNullOrEmpty($POSTGRES_PASSWORD)) {
        $POSTGRES_PASSWORD = "your-super-secret-postgres-password-change-me"
        Write-Host "Warning: Using default password. Check .env file!" -ForegroundColor Yellow
    }
    
    # Экспортируем схему и данные
    $DB_EXPORT_FILE = Join-Path $DB_EXPORT_DIR "supabase_backup_$TIMESTAMP.sql"
    
    Write-Host "Exporting database to: $DB_EXPORT_FILE"
    Write-Host "This may take a while..."
    
    docker exec $SUPABASE_CONTAINER pg_dump -U postgres -d postgres --clean --if-exists --create > $DB_EXPORT_FILE
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $DB_EXPORT_FILE) -and (Get-Item $DB_EXPORT_FILE).Length -gt 0) {
        # Сжимаем SQL файл
        Write-Host "Compressing database backup..."
        
        $gzipAvailable = $false
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            wsl gzip -f $(wsl wslpath -a $DB_EXPORT_FILE)
            if ($LASTEXITCODE -eq 0) {
                $DB_EXPORT_FILE = "$DB_EXPORT_FILE.gz"
                $gzipAvailable = $true
            }
        }
        
        if (-not $gzipAvailable -and (Test-Path "C:\Program Files\Git\usr\bin\gzip.exe")) {
            & "C:\Program Files\Git\usr\bin\gzip.exe" -f $DB_EXPORT_FILE
            if ($LASTEXITCODE -eq 0) {
                $DB_EXPORT_FILE = "$DB_EXPORT_FILE.gz"
                $gzipAvailable = $true
            }
        }
        
        if (-not $gzipAvailable) {
            $ZIP_FILE = "$DB_EXPORT_FILE.zip"
            Compress-Archive -Path $DB_EXPORT_FILE -DestinationPath $ZIP_FILE -Force
            Remove-Item $DB_EXPORT_FILE
            $DB_EXPORT_FILE = $ZIP_FILE
        }
        
        $DB_SIZE = [math]::Round((Get-Item $DB_EXPORT_FILE).Length / 1MB, 2)
        Write-Host "  OK! Database backup: $DB_SIZE MB" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "Warning: Database export failed or empty" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "Warning: Supabase container is not running. Skipping database export." -ForegroundColor Yellow
    Write-Host "Start it with: docker compose -f docker-compose.prod.yml up -d supabase" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================
# ШАГ 4: Экспорт Storage данных
# ============================================
Write-Host "Step 4: Exporting Storage data..." -ForegroundColor Blue
Write-Host ""

# Получаем список всех volumes
$allVolumes = docker volume ls --format "{{.Name}}"

# Ищем volumes связанные с Supabase (БД и Storage)
$storageVolumes = $allVolumes | Select-String -Pattern "storage|supabase.*data|mediavelichia.*data"

if ($storageVolumes) {
    $STORAGE_EXPORT_DIR_ABS = (Resolve-Path $STORAGE_EXPORT_DIR).Path
    
    foreach ($volumeName in $storageVolumes) {
        $volumeName = $volumeName.ToString().Trim()
        Write-Host "Found volume: $volumeName" -ForegroundColor Green
        
        $volumeFileName = $volumeName -replace '[^a-zA-Z0-9]', '_'
        $STORAGE_EXPORT_FILE = Join-Path $STORAGE_EXPORT_DIR "${volumeFileName}_backup_$TIMESTAMP.tar.gz"
        
        Write-Host "Exporting volume to: $STORAGE_EXPORT_FILE"
        Write-Host "This may take a while..."
        
        # Создаем временный контейнер для экспорта volume
        docker run --rm -v "${volumeName}:/data" -v "${STORAGE_EXPORT_DIR_ABS}:/backup" alpine tar czf /backup/${volumeFileName}_backup_$TIMESTAMP.tar.gz -C /data .
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $STORAGE_EXPORT_FILE)) {
            $STORAGE_SIZE = [math]::Round((Get-Item $STORAGE_EXPORT_FILE).Length / 1MB, 2)
            Write-Host "  OK! Volume backup: $STORAGE_SIZE MB" -ForegroundColor Green
            Write-Host ""
        } else {
            Write-Host "  Warning: Volume export failed or file not created" -ForegroundColor Yellow
            Write-Host ""
        }
    }
} else {
    Write-Host "Info: Storage volumes not found. Storage may be empty or using cloud Supabase." -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# ШАГ 5: Создание скриптов для импорта
# ============================================
Write-Host "Step 5: Creating import scripts..." -ForegroundColor Blue
Write-Host ""

# Скрипт для импорта образов
$IMPORT_IMAGES_SCRIPT = Join-Path $EXPORT_DIR "import-images.sh"
@"
#!/bin/bash
# Скрипт для импорта Docker образов на сервере

set -e

SCRIPT_DIR="`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)"
cd "`${SCRIPT_DIR}/images"

shopt -s nullglob

for FILE in *.tar.gz *.tar.zip *.tar; do
    if [ -f "`$FILE" ]; then
        echo "Importing: `$FILE"
        if [[ "`$FILE" == *.gz ]]; then
            gunzip -c "`$FILE" | docker load
        elif [[ "`$FILE" == *.zip ]]; then
            unzip -p "`$FILE" | docker load
        else
            docker load -i "`$FILE"
        fi
        echo "OK: `$FILE"
    fi
done

echo "Images imported!"
"@ | Out-File -FilePath $IMPORT_IMAGES_SCRIPT -Encoding UTF8

# Скрипт для импорта БД
$IMPORT_DB_SCRIPT = Join-Path $EXPORT_DIR "import-database.sh"
@"
#!/bin/bash
# Скрипт для импорта базы данных на сервере

set -e

SCRIPT_DIR="`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)"
cd "`${SCRIPT_DIR}/database"

# Находим файл бэкапа
BACKUP_FILE=`$(ls -t *.sql.gz *.sql.zip *.sql 2>/dev/null | head -1)

if [ -z "`$BACKUP_FILE" ]; then
    echo "Error: No database backup file found"
    exit 1
fi

echo "Importing database from: `$BACKUP_FILE"

# Распаковываем если нужно
if [[ "`$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "`$BACKUP_FILE" | docker exec -i mediavelichie-supabase-db psql -U postgres
elif [[ "`$BACKUP_FILE" == *.zip ]]; then
    unzip -p "`$BACKUP_FILE" | docker exec -i mediavelichie-supabase-db psql -U postgres
else
    docker exec -i mediavelichie-supabase-db psql -U postgres < "`$BACKUP_FILE"
fi

echo "Database imported!"
"@ | Out-File -FilePath $IMPORT_DB_SCRIPT -Encoding UTF8

# Скрипт для импорта Storage
$IMPORT_STORAGE_SCRIPT = Join-Path $EXPORT_DIR "import-storage.sh"
@"
#!/bin/bash
# Скрипт для импорта Storage данных на сервере

set -e

SCRIPT_DIR="`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)"
cd "`${SCRIPT_DIR}/storage"

STORAGE_VOLUME="mediavelichie_supabase-db-data"
BACKUP_FILE=`$(ls -t storage_backup_*.tar.gz storage_backup_*.tar 2>/dev/null | head -1)

if [ -z "`$BACKUP_FILE" ]; then
    echo "Warning: No storage backup file found. Skipping storage import."
    exit 0
fi

echo "Importing storage from: `$BACKUP_FILE"

# Создаем временный контейнер для импорта
if [[ "`$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "`$BACKUP_FILE" | docker run --rm -i -v "`${STORAGE_VOLUME}:/data" alpine tar xzf - -C /data
else
    docker run --rm -i -v "`${STORAGE_VOLUME}:/data" -v "`$(pwd):/backup" alpine tar xf /backup/`$BACKUP_FILE -C /data
fi

echo "Storage imported!"
"@ | Out-File -FilePath $IMPORT_STORAGE_SCRIPT -Encoding UTF8

# Главный скрипт импорта
$MAIN_IMPORT_SCRIPT = Join-Path $EXPORT_DIR "import-all.sh"
@"
#!/bin/bash
# Главный скрипт для импорта всего на сервере

set -e

echo "=========================================="
echo "Importing Docker Images + Supabase Data"
echo "=========================================="
echo ""

# Импорт образов
echo "Step 1: Importing Docker images..."
chmod +x import-images.sh
./import-images.sh

echo ""

# Импорт БД
echo "Step 2: Importing database..."
chmod +x import-database.sh
./import-database.sh

echo ""

# Импорт Storage
echo "Step 3: Importing storage..."
chmod +x import-storage.sh
./import-storage.sh || echo "Storage import skipped (no backup file)"

echo ""
echo "=========================================="
echo "Import completed!"
echo "=========================================="
"@ | Out-File -FilePath $MAIN_IMPORT_SCRIPT -Encoding UTF8

Write-Host "Created import scripts:" -ForegroundColor Green
Write-Host "  - import-all.sh (main script)"
Write-Host "  - import-images.sh"
Write-Host "  - import-database.sh"
Write-Host "  - import-storage.sh"
Write-Host ""

# ============================================
# ИТОГИ
# ============================================
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Export completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Exported files:" -ForegroundColor Blue
Write-Host ""

Write-Host "Docker Images:" -ForegroundColor Yellow
$EXPORTED_IMAGES | ForEach-Object {
    $FILE_SIZE = [math]::Round((Get-Item $_).Length / 1MB, 2)
    $FILENAME = Split-Path $_ -Leaf
    Write-Host "  - images/$FILENAME ($FILE_SIZE MB)"
}

Write-Host ""
Write-Host "Database:" -ForegroundColor Yellow
$dbFiles = Get-ChildItem $DB_EXPORT_DIR -Filter "supabase_backup_*" -ErrorAction SilentlyContinue
if ($dbFiles) {
    $dbFiles | ForEach-Object {
        $DB_SIZE = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  - database/$($_.Name) ($DB_SIZE MB)"
    }
} else {
    Write-Host "  - (not exported - container not running)"
}

Write-Host ""
Write-Host "Storage:" -ForegroundColor Yellow
$storageFiles = Get-ChildItem $STORAGE_EXPORT_DIR -Filter "*_backup_*" -ErrorAction SilentlyContinue
if ($storageFiles) {
    $storageFiles | ForEach-Object {
        $STORAGE_SIZE = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  - storage/$($_.Name) ($STORAGE_SIZE MB)"
    }
} else {
    Write-Host "  - (not exported - volume not found or empty)"
}

Write-Host ""

$TOTAL_SIZE = [math]::Round((Get-ChildItem $EXPORT_DIR -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
Write-Host "Total size: $TOTAL_SIZE MB" -ForegroundColor Blue
Write-Host ""
Write-Host "Export directory: $EXPORT_DIR" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Transfer '$EXPORT_DIR' directory to server"
Write-Host "  2. On server: cd /opt/mediavelichia/docker-images-export"
Write-Host "  3. Run: chmod +x import-all.sh && ./import-all.sh"
Write-Host ""
