#!/bin/bash

# Скрипт для импорта и пересборки Docker образов на сервере
# Использование: ./rebuild-images-on-server.sh
# 
# Требования:
# - Файлы образов должны быть в /opt/mediavelichia/docker-images-import/
# - docker-compose.prod.yml должен быть в /opt/mediavelichia/

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Пути
IMPORT_DIR="/opt/mediavelichia/docker-images-import"
PROJECT_DIR="/opt/mediavelichia"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"

echo "=========================================="
echo -e "${CYAN}Rebuilding Docker Images on Server${NC}"
echo "=========================================="
echo ""

# Проверка существования директорий
if [ ! -d "$IMPORT_DIR" ]; then
    echo -e "${RED}Error: Directory $IMPORT_DIR not found!${NC}"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: Docker Compose file $COMPOSE_FILE not found!${NC}"
    exit 1
fi

# Переходим в директорию с образами
cd "$IMPORT_DIR"

echo -e "${BLUE}Step 1: Checking dependencies...${NC}"

# Проверяем и устанавливаем unzip если нужно
if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}unzip not found. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y -qq unzip > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y -q unzip > /dev/null 2>&1
    elif command -v apk &> /dev/null; then
        apk add --quiet unzip > /dev/null 2>&1
    else
        echo -e "${RED}Warning: Cannot install unzip automatically. Please install it manually.${NC}"
        echo "  Debian/Ubuntu: apt-get install -y unzip"
        echo "  CentOS/RHEL: yum install -y unzip"
        echo "  Alpine: apk add unzip"
    fi
fi

# Проверяем наличие unzip после установки
if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}Warning: unzip still not available. Will try alternative methods for .zip files.${NC}"
fi

echo ""

echo -e "${BLUE}Step 2: Importing Docker images...${NC}"
echo ""

# Счетчик импортированных образов
IMPORTED_COUNT=0

# Импорт .tar.gz файлов
shopt -s nullglob
for FILE in *.tar.gz; do
    if [ -f "$FILE" ]; then
        echo -e "${YELLOW}Importing:${NC} $FILE"
        gunzip -c "$FILE" | docker load
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Image imported: $FILE"
            ((IMPORTED_COUNT++))
        else
            echo -e "${RED}✗${NC} Failed to import: $FILE"
        fi
        echo ""
    fi
done

# Импорт .tar.zip файлов
for FILE in *.tar.zip; do
    if [ -f "$FILE" ]; then
        echo -e "${YELLOW}Importing:${NC} $FILE"
        
        # Пробуем разные методы распаковки
        if command -v unzip &> /dev/null; then
            # Метод 1: Используем unzip
            unzip -p "$FILE" | docker load
        elif command -v python3 &> /dev/null; then
            # Метод 2: Используем Python для распаковки
            python3 -c "import zipfile, sys; z=zipfile.ZipFile('$FILE'); sys.stdout.buffer.write(z.read(z.namelist()[0]))" | docker load
        elif command -v python &> /dev/null; then
            # Метод 3: Используем Python 2 (если доступен)
            python -c "import zipfile, sys; z=zipfile.ZipFile('$FILE'); sys.stdout.write(z.read(z.namelist()[0]))" | docker load
        else
            echo -e "${RED}✗${NC} Cannot import $FILE: unzip and python not available"
            echo "Please install unzip: apt-get install -y unzip"
            continue
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Image imported: $FILE"
            ((IMPORTED_COUNT++))
        else
            echo -e "${RED}✗${NC} Failed to import: $FILE"
        fi
        echo ""
    fi
done

# Импорт .tar файлов (без сжатия)
for FILE in *.tar; do
    # Пропускаем .tar.gz и .tar.zip (уже обработаны)
    if [[ "$FILE" != *.gz ]] && [[ "$FILE" != *.zip ]]; then
        if [ -f "$FILE" ]; then
            echo -e "${YELLOW}Importing:${NC} $FILE"
            docker load -i "$FILE"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓${NC} Image imported: $FILE"
                ((IMPORTED_COUNT++))
            else
                echo -e "${RED}✗${NC} Failed to import: $FILE"
            fi
            echo ""
        fi
    fi
done
shopt -u nullglob

if [ $IMPORTED_COUNT -eq 0 ]; then
    echo -e "${YELLOW}Warning: No image files found in $IMPORT_DIR${NC}"
    echo "Looking for: *.tar.gz, *.tar.zip, *.tar"
    echo ""
fi

echo "=========================================="
echo -e "${GREEN}Imported $IMPORTED_COUNT image(s)${NC}"
echo "=========================================="
echo ""

# Показываем импортированные образы
echo -e "${BLUE}Imported images:${NC}"
docker images | grep -E "mediavelichia|REPOSITORY" || echo "No custom images found"
echo ""

# Переходим в директорию проекта
cd "$PROJECT_DIR"

echo -e "${BLUE}Step 3: Stopping existing containers...${NC}"
docker compose -f "$COMPOSE_FILE" down
echo ""

echo -e "${BLUE}Step 4: Rebuilding containers...${NC}"
echo "This may take a few minutes..."
docker compose -f "$COMPOSE_FILE" build --no-cache
echo ""

echo -e "${BLUE}Step 5: Starting containers...${NC}"
docker compose -f "$COMPOSE_FILE" up -d
echo ""

echo -e "${BLUE}Step 6: Checking container status...${NC}"
sleep 5
docker compose -f "$COMPOSE_FILE" ps
echo ""

echo "=========================================="
echo -e "${GREEN}Rebuild completed!${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo "  View logs:        docker compose -f $COMPOSE_FILE logs -f"
echo "  Check status:     docker compose -f $COMPOSE_FILE ps"
echo "  Stop containers:  docker compose -f $COMPOSE_FILE down"
echo "  Restart:          docker compose -f $COMPOSE_FILE restart"
echo ""
