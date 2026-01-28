#!/bin/bash

# Скрипт для проверки состояния сервера Mediavelichia
# Использование: ./check-server-status.sh

echo "=========================================="
echo "Проверка состояния сервера Mediavelichia"
echo "=========================================="
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки команды
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 установлен"
        return 0
    else
        echo -e "${RED}✗${NC} $1 НЕ установлен"
        return 1
    fi
}

# Функция для вывода секции
print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# 1. Информация о системе
print_section "1. Информация о системе"
echo "ОС: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Ядро: $(uname -r)"
echo "Архитектура: $(uname -m)"
echo "Время работы: $(uptime -p)"
echo "Дата/время: $(date)"

# 2. Ресурсы системы
print_section "2. Ресурсы системы"
echo "Память:"
free -h
echo ""
echo "Диск:"
df -h / | tail -1
echo ""
echo "CPU:"
echo "Количество ядер: $(nproc)"
echo "Загрузка: $(uptime | awk -F'load average:' '{print $2}')"

# 3. Проверка установленных пакетов
print_section "3. Установленные пакеты"
check_command docker
if check_command docker; then
    echo "  Версия Docker: $(docker --version)"
    echo "  Docker Compose: $(docker compose version 2>/dev/null || echo 'не установлен')"
fi

check_command git
if check_command git; then
    echo "  Версия Git: $(git --version)"
fi

check_command curl
check_command wget
check_command nano
check_command ufw

# 4. Статус Docker
print_section "4. Статус Docker"
if command -v docker &> /dev/null; then
    echo "Статус Docker сервиса:"
    sudo systemctl status docker --no-pager -l | head -5
    echo ""
    
    echo "Docker контейнеры:"
    docker ps -a
    echo ""
    
    echo "Docker образы:"
    docker images
    echo ""
    
    echo "Docker volumes:"
    docker volume ls
    echo ""
    
    echo "Docker networks:"
    docker network ls
else
    echo -e "${RED}Docker не установлен${NC}"
fi

# 5. Проверка портов
print_section "5. Проверка портов"
echo "Открытые порты:"
if command -v ss &> /dev/null; then
    ss -tlnp | grep -E ':(22|80|443|5000|5432)' || echo "Нет открытых портов на 22, 80, 443, 5000, 5432"
else
    netstat -tlnp 2>/dev/null | grep -E ':(22|80|443|5000|5432)' || echo "Нет открытых портов на 22, 80, 443, 5000, 5432"
fi

# 6. Проверка директории проекта
print_section "6. Проверка директории проекта"
PROJECT_DIR="/opt/mediavelichia"
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${GREEN}✓${NC} Директория проекта существует: $PROJECT_DIR"
    echo "Содержимое:"
    ls -lah $PROJECT_DIR | head -20
    echo ""
    
    if [ -f "$PROJECT_DIR/.env" ]; then
        echo -e "${GREEN}✓${NC} Файл .env существует"
        echo "Переменные (без значений):"
        grep -v "^#" $PROJECT_DIR/.env | grep "=" | cut -d'=' -f1 | sed 's/^/  - /'
    else
        echo -e "${YELLOW}⚠${NC} Файл .env НЕ найден"
    fi
    
    if [ -f "$PROJECT_DIR/docker-compose.prod.yml" ] || [ -f "$PROJECT_DIR/docker-compose.prod.cloud.yml" ]; then
        echo -e "${GREEN}✓${NC} Docker Compose файлы найдены"
    else
        echo -e "${YELLOW}⚠${NC} Docker Compose файлы НЕ найдены"
    fi
    
    if [ -d "$PROJECT_DIR/.git" ]; then
        echo -e "${GREEN}✓${NC} Git репозиторий инициализирован"
        cd $PROJECT_DIR
        echo "  Текущая ветка: $(git branch --show-current 2>/dev/null || echo 'не определена')"
        echo "  Последний коммит: $(git log -1 --format='%h - %s' 2>/dev/null || echo 'нет коммитов')"
    else
        echo -e "${YELLOW}⚠${NC} Git репозиторий НЕ инициализирован"
    fi
else
    echo -e "${RED}✗${NC} Директория проекта НЕ существует: $PROJECT_DIR"
fi

# 7. Проверка контейнеров проекта
print_section "7. Контейнеры проекта Mediavelichia"
if command -v docker &> /dev/null; then
    CONTAINERS=("mediavelichie-web" "mediavelichie-editor" "mediavelichie-supabase-db")
    for container in "${CONTAINERS[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            echo -e "${GREEN}✓${NC} Контейнер $container существует"
            echo "  Статус: $(docker inspect --format='{{.State.Status}}' $container 2>/dev/null)"
            echo "  Запущен: $(docker inspect --format='{{.State.Running}}' $container 2>/dev/null)"
            echo "  Health: $(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo 'нет healthcheck')"
        else
            echo -e "${YELLOW}⚠${NC} Контейнер $container НЕ найден"
        fi
    done
fi

# 8. Проверка сетевых подключений
print_section "8. Сетевые подключения"
if command -v docker &> /dev/null; then
    echo "Docker сети:"
    docker network ls | grep mediavelichie || echo "Сети mediavelichie не найдены"
fi

# 9. Проверка firewall
print_section "9. Firewall (UFW)"
if command -v ufw &> /dev/null; then
    echo "Статус UFW:"
    sudo ufw status verbose
else
    echo -e "${YELLOW}UFW не установлен${NC}"
fi

# 10. Проверка логов (последние строки)
print_section "10. Последние логи системы"
echo "Последние 10 строк systemd логов:"
journalctl -n 10 --no-pager 2>/dev/null || echo "Не удалось получить логи"

# 11. Проверка Docker логов (если контейнеры запущены)
print_section "11. Логи Docker контейнеров"
if command -v docker &> /dev/null; then
    for container in "${CONTAINERS[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "--- Логи $container (последние 5 строк) ---"
            docker logs --tail 5 $container 2>&1 || echo "Не удалось получить логи"
            echo ""
        fi
    done
fi

# 12. Рекомендации
print_section "12. Рекомендации"
RECOMMENDATIONS=()

if ! command -v docker &> /dev/null; then
    RECOMMENDATIONS+=("Установить Docker и Docker Compose")
fi

if [ ! -d "$PROJECT_DIR" ]; then
    RECOMMENDATIONS+=("Создать директорию проекта: mkdir -p $PROJECT_DIR")
fi

if [ ! -f "$PROJECT_DIR/.env" ]; then
    RECOMMENDATIONS+=("Создать файл .env на основе .env.example")
fi

if [ ${#RECOMMENDATIONS[@]} -eq 0 ]; then
    echo -e "${GREEN}Все проверки пройдены успешно!${NC}"
else
    echo -e "${YELLOW}Рекомендуется выполнить:${NC}"
    for i in "${!RECOMMENDATIONS[@]}"; do
        echo "$((i+1)). ${RECOMMENDATIONS[$i]}"
    done
fi

echo ""
echo "=========================================="
echo "Проверка завершена"
echo "=========================================="
