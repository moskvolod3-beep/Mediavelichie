#!/bin/bash

# Скрипт проверки готовности к деплою
# Использование: ./check-deployment-ready.sh

echo "=========================================="
echo "Проверка готовности к деплою"
echo "=========================================="
echo ""

PROJECT_DIR="/opt/mediavelichia"
ERRORS=0
WARNINGS=0

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

check_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

check_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# 1. Проверка Docker
echo "1. Проверка Docker"
if command -v docker &> /dev/null; then
    check_ok "Docker установлен: $(docker --version)"
    
    if docker ps &> /dev/null; then
        check_ok "Docker работает"
    else
        check_error "Docker не запущен или нет прав доступа"
    fi
    
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        check_ok "Docker Compose установлен: $(docker compose version)"
    else
        check_error "Docker Compose не установлен"
    fi
else
    check_error "Docker не установлен"
fi

# 2. Проверка директории проекта
echo ""
echo "2. Проверка директории проекта"
if [ -d "$PROJECT_DIR" ]; then
    check_ok "Директория проекта существует: $PROJECT_DIR"
    
    if [ -d "$PROJECT_DIR/.git" ]; then
        check_ok "Git репозиторий инициализирован"
        cd "$PROJECT_DIR"
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
        if [ -n "$CURRENT_BRANCH" ]; then
            check_ok "Текущая ветка: $CURRENT_BRANCH"
        else
            check_warning "Не удалось определить текущую ветку"
        fi
    else
        check_error "Git репозиторий не инициализирован"
    fi
else
    check_error "Директория проекта не существует: $PROJECT_DIR"
fi

# 3. Проверка файлов конфигурации
echo ""
echo "3. Проверка файлов конфигурации"
cd "$PROJECT_DIR" 2>/dev/null || exit 1

if [ -f "docker-compose.prod.cloud.yml" ]; then
    check_ok "docker-compose.prod.cloud.yml существует"
    
    # Проверка синтаксиса YAML
    if docker compose -f docker-compose.prod.cloud.yml config &> /dev/null; then
        check_ok "Синтаксис docker-compose.prod.cloud.yml корректен"
    else
        check_error "Ошибка синтаксиса в docker-compose.prod.cloud.yml"
        echo "   Запустите: docker compose -f docker-compose.prod.cloud.yml config"
    fi
else
    check_error "docker-compose.prod.cloud.yml не найден"
fi

if [ -f "Dockerfile" ]; then
    check_ok "Dockerfile существует"
else
    check_error "Dockerfile не найден"
fi

# 4. Проверка .env файла
echo ""
echo "4. Проверка переменных окружения"
if [ -f ".env" ]; then
    check_ok "Файл .env существует"
    
    # Проверка обязательных переменных
    source .env 2>/dev/null || true
    
    if [ -n "$SUPABASE_URL" ] && [ "$SUPABASE_URL" != "https://your-project.supabase.co" ]; then
        check_ok "SUPABASE_URL настроен"
    else
        check_error "SUPABASE_URL не настроен или содержит placeholder"
    fi
    
    if [ -n "$SUPABASE_ANON_KEY" ] && [ "$SUPABASE_ANON_KEY" != "your-anon-public-key-here" ]; then
        check_ok "SUPABASE_ANON_KEY настроен"
    else
        check_error "SUPABASE_ANON_KEY не настроен или содержит placeholder"
    fi
    
    if [ -n "$SUPABASE_SERVICE_KEY" ] && [ "$SUPABASE_SERVICE_KEY" != "your-service-role-key-here" ]; then
        check_ok "SUPABASE_SERVICE_KEY настроен"
    else
        check_warning "SUPABASE_SERVICE_KEY не настроен (нужен для backend)"
    fi
    
    if [ -n "$SUPABASE_BUCKET" ]; then
        check_ok "SUPABASE_BUCKET настроен: $SUPABASE_BUCKET"
    else
        check_warning "SUPABASE_BUCKET не настроен (будет использован 'portfolio' по умолчанию)"
    fi
else
    check_error "Файл .env не найден"
    echo "   Создайте: cp .env.example .env && nano .env"
fi

# 5. Проверка портов
echo ""
echo "5. Проверка портов"
PORTS=(80 443 5000)
for port in "${PORTS[@]}"; do
    if command -v ss &> /dev/null; then
        if ss -tlnp | grep -q ":$port "; then
            check_warning "Порт $port уже занят"
        else
            check_ok "Порт $port свободен"
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            check_warning "Порт $port уже занят"
        else
            check_ok "Порт $port свободен"
        fi
    else
        check_warning "Не удалось проверить порт $port (ss/netstat не найдены)"
    fi
done

# 6. Проверка существующих контейнеров
echo ""
echo "6. Проверка существующих контейнеров"
if command -v docker &> /dev/null; then
    EXISTING_CONTAINERS=$(docker ps -a --format '{{.Names}}' | grep -E 'mediavelichie-(web|editor|supabase)' || true)
    if [ -n "$EXISTING_CONTAINERS" ]; then
        check_warning "Найдены существующие контейнеры:"
        echo "$EXISTING_CONTAINERS" | while read container; do
            STATUS=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
            echo "   - $container ($STATUS)"
        done
    else
        check_ok "Существующие контейнеры не найдены (чистый запуск)"
    fi
fi

# 7. Проверка места на диске
echo ""
echo "7. Проверка места на диске"
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    check_ok "Свободного места достаточно: $(df -h / | tail -1 | awk '{print $4}') свободно"
else
    check_warning "Мало свободного места: использовано ${DISK_USAGE}%"
fi

# 8. Проверка памяти
echo ""
echo "8. Проверка памяти"
if command -v free &> /dev/null; then
    MEM_AVAILABLE=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [ "$MEM_AVAILABLE" -gt 1024 ]; then
        check_ok "Доступно памяти: ${MEM_AVAILABLE}MB"
    else
        check_warning "Мало доступной памяти: ${MEM_AVAILABLE}MB (рекомендуется минимум 2GB)"
    fi
fi

# Итоги
echo ""
echo "=========================================="
echo "Итоги проверки"
echo "=========================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Все проверки пройдены успешно!${NC}"
    echo ""
    echo "Готово к запуску. Выполните:"
    echo "  cd $PROJECT_DIR"
    echo "  docker compose -f docker-compose.prod.cloud.yml up -d --build"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Есть предупреждения ($WARNINGS), но можно запускать${NC}"
    echo ""
    echo "Можно запускать. Выполните:"
    echo "  cd $PROJECT_DIR"
    echo "  docker compose -f docker-compose.prod.cloud.yml up -d --build"
else
    echo -e "${RED}✗ Найдены критические ошибки ($ERRORS)${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}  и предупреждения ($WARNINGS)${NC}"
    fi
    echo ""
    echo "Исправьте ошибки перед запуском."
    echo "См. инструкции в DEPLOY.md и FIX_YAML_ERROR.md"
fi

echo ""
