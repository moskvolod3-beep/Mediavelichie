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

echo -e "${BLUE}Step 1: Importing Docker images...${NC}"
echo ""

# Счетчик импортированных образов
IMPORTED_COUNT=0

# Импорт .tar.gz файлов
for FILE in *.tar.gz 2>/dev/null; do
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
for FILE in *.tar.zip 2>/dev/null; do
    if [ -f "$FILE" ]; then
        echo -e "${YELLOW}Importing:${NC} $FILE"
        unzip -p "$FILE" | docker load
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
for FILE in *.tar 2>/dev/null; do
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

echo -e "${BLUE}Step 2: Stopping existing containers...${NC}"
docker compose -f "$COMPOSE_FILE" down
echo ""

echo -e "${BLUE}Step 3: Rebuilding containers...${NC}"
echo "This may take a few minutes..."
docker compose -f "$COMPOSE_FILE" build --no-cache
echo ""

echo -e "${BLUE}Step 4: Starting containers...${NC}"
docker compose -f "$COMPOSE_FILE" up -d
echo ""

echo -e "${BLUE}Step 5: Checking container status...${NC}"
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
