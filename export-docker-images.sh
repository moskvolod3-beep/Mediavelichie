#!/bin/bash

# Скрипт для экспорта Docker образов в файлы для переноса на сервер
# Использование: ./export-docker-images.sh

set -e

EXPORT_DIR="./docker-images-export"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Экспорт Docker образов для переноса на сервер"
echo "=========================================="
echo ""

# Создаем директорию для экспорта
mkdir -p "$EXPORT_DIR"

# Список образов для экспорта
IMAGES=(
    "mediavelichie-web:latest"
    "mediavelichie-editor:latest"
    "supabase/postgres:15.1.0.117"
    "supabase/studio:latest"
)

# Также проверяем образы из docker-compose
echo "Поиск локальных образов..."
echo ""

# Собираем образы если они еще не собраны
echo -e "${BLUE}Сборка образов из docker-compose.prod.yml...${NC}"
docker compose -f docker-compose.prod.yml build --quiet

echo ""
echo -e "${BLUE}Экспорт образов...${NC}"
echo ""

EXPORTED_FILES=()

for IMAGE in "${IMAGES[@]}"; do
    # Проверяем существует ли образ
    if docker image inspect "$IMAGE" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Найден образ: $IMAGE"
        
        # Создаем имя файла из имени образа
        FILENAME=$(echo "$IMAGE" | tr '/:' '_')
        EXPORT_FILE="$EXPORT_DIR/${FILENAME}.tar"
        
        echo "  Экспорт в: $EXPORT_FILE"
        docker save "$IMAGE" -o "$EXPORT_FILE"
        
        # Сжимаем файл
        echo "  Сжатие..."
        gzip -f "$EXPORT_FILE"
        
        EXPORTED_FILES+=("${EXPORT_FILE}.gz")
        
        FILE_SIZE=$(du -h "${EXPORT_FILE}.gz" | cut -f1)
        echo -e "  ${GREEN}✓${NC} Готово! Размер: $FILE_SIZE"
        echo ""
    else
        echo -e "${YELLOW}⚠${NC} Образ не найден: $IMAGE (пропускаем)"
        echo ""
    fi
done

# Также экспортируем все образы проекта
echo -e "${BLUE}Поиск образов проекта...${NC}"
PROJECT_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "mediavelichie|mediavelichia" || true)

if [ -n "$PROJECT_IMAGES" ]; then
    while IFS= read -r IMAGE; do
        if [[ ! " ${IMAGES[@]} " =~ " ${IMAGE} " ]]; then
            echo -e "${GREEN}✓${NC} Найден дополнительный образ: $IMAGE"
            
            FILENAME=$(echo "$IMAGE" | tr '/:' '_')
            EXPORT_FILE="$EXPORT_DIR/${FILENAME}.tar"
            
            echo "  Экспорт в: $EXPORT_FILE"
            docker save "$IMAGE" -o "$EXPORT_FILE"
            
            echo "  Сжатие..."
            gzip -f "$EXPORT_FILE"
            
            EXPORTED_FILES+=("${EXPORT_FILE}.gz")
            
            FILE_SIZE=$(du -h "${EXPORT_FILE}.gz" | cut -f1)
            echo -e "  ${GREEN}✓${NC} Готово! Размер: $FILE_SIZE"
            echo ""
        fi
    done <<< "$PROJECT_IMAGES"
fi

# Создаем скрипт для импорта на сервере
IMPORT_SCRIPT="$EXPORT_DIR/import-images.sh"
cat > "$IMPORT_SCRIPT" << 'EOF'
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

# Импортируем все .tar.gz файлы в текущей директории
for FILE in *.tar.gz; do
    if [ -f "$FILE" ]; then
        echo -e "${BLUE}Импорт:${NC} $FILE"
        
        # Распаковываем и импортируем
        gunzip -c "$FILE" | docker load
        
        echo -e "${GREEN}✓${NC} Образ импортирован: $FILE"
        echo ""
    fi
done

echo "=========================================="
echo -e "${GREEN}Импорт завершен!${NC}"
echo "=========================================="
echo ""
echo "Проверка импортированных образов:"
docker images | grep -E "mediavelichie|supabase" || echo "Образы не найдены"
EOF

chmod +x "$IMPORT_SCRIPT"

# Создаем README с инструкциями
README_FILE="$EXPORT_DIR/README.md"
cat > "$README_FILE" << EOF
# Экспорт Docker образов

Дата экспорта: $(date '+%Y-%m-%d %H:%M:%S')

## Экспортированные образы

$(for FILE in "${EXPORTED_FILES[@]}"; do
    FILE_SIZE=$(du -h "$FILE" | cut -f1)
    echo "- \`$(basename "$FILE")\` ($FILE_SIZE)"
done)

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

## Альтернативный способ (без сжатия)

Если на сервере нет gzip или возникают проблемы:

\`\`\`bash
# Импорт каждого образа вручную
for FILE in *.tar.gz; do
    gunzip -c "\$FILE" | docker load
done
\`\`\`

## Размеры файлов

$(for FILE in "${EXPORTED_FILES[@]}"; do
    FILE_SIZE=$(du -h "$FILE" | cut -f1)
    echo "- \`$(basename "$FILE")\`: $FILE_SIZE"
done)

**Общий размер:** $(du -sh "$EXPORT_DIR" | cut -f1)
EOF

echo "=========================================="
echo -e "${GREEN}Экспорт завершен!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Экспортированные файлы:${NC}"
for FILE in "${EXPORTED_FILES[@]}"; do
    FILE_SIZE=$(du -h "$FILE" | cut -f1)
    echo "  - $(basename "$FILE") ($FILE_SIZE)"
done

TOTAL_SIZE=$(du -sh "$EXPORT_DIR" | cut -f1)
echo ""
echo -e "${BLUE}Общий размер:${NC} $TOTAL_SIZE"
echo ""
echo -e "${BLUE}Директория экспорта:${NC} $EXPORT_DIR"
echo ""
echo "Следующие шаги:"
echo "  1. Передайте содержимое директории '$EXPORT_DIR' на сервер"
echo "  2. На сервере выполните: cd /opt/mediavelichia/docker-images-import && ./import-images.sh"
echo ""
echo -e "${YELLOW}Примечание:${NC} Файлы сжаты с помощью gzip для экономии места"
echo ""
