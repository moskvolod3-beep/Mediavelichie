#!/bin/bash

# Скрипт установки и настройки локального Supabase контейнера
# Использование: ./setup-local-supabase.sh

set -e

PROJECT_DIR="/opt/mediavelichia"
ENV_FILE="$PROJECT_DIR/.env"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Установка и настройка локального Supabase"
echo "=========================================="
echo ""

cd "$PROJECT_DIR" || {
    echo -e "${RED}Ошибка: директория $PROJECT_DIR не существует${NC}"
    exit 1
}

# Функция генерации случайной строки
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Функция генерации JWT токена для локального Supabase
generate_jwt_token() {
    local role=$1
    local jwt_secret=$2
    
    # Для локального Supabase используем стандартный формат JWT
    # Header: {"alg":"HS256","typ":"JWT"}
    # Payload: {"iss":"supabase-demo","role":"$role","exp":1983812996}
    
    # Если Python доступен, используем его для генерации JWT
    if command -v python3 &> /dev/null; then
        python3 << EOF
import hmac
import hashlib
import base64
import json
import time

header = {"alg": "HS256", "typ": "JWT"}
payload = {
    "iss": "supabase-demo",
    "role": "$role",
    "exp": 1983812996  # Далекая дата в будущем для локального использования
}

def base64url_encode(data):
    return base64.b64encode(data).decode('utf-8').rstrip('=').replace('+', '-').replace('/', '_')

header_encoded = base64url_encode(json.dumps(header).encode('utf-8'))
payload_encoded = base64url_encode(json.dumps(payload).encode('utf-8'))

message = f"{header_encoded}.{payload_encoded}"
signature = hmac.new(
    "$jwt_secret".encode('utf-8'),
    message.encode('utf-8'),
    hashlib.sha256
).digest()
signature_encoded = base64url_encode(signature)

token = f"{message}.{signature_encoded}"
print(token)
EOF
    else
        # Fallback: используем стандартный токен для локального Supabase
        if [ "$role" = "anon" ]; then
            echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
        else
            echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
        fi
    fi
}

# Шаг 1: Проверка и создание .env файла
echo "1. Проверка файла .env..."
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Файл .env не найден, создаем из .env.example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example "$ENV_FILE"
    else
        echo -e "${RED}Файл .env.example не найден${NC}"
        exit 1
    fi
fi

# Шаг 2: Генерация секретов если их нет
echo ""
echo "2. Генерация секретов..."

source "$ENV_FILE" 2>/dev/null || true

# Генерация POSTGRES_PASSWORD
if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" = "your-super-secret-postgres-password-change-me" ]; then
    POSTGRES_PASSWORD=$(generate_secret)
    echo -e "${GREEN}✓ Сгенерирован POSTGRES_PASSWORD${NC}"
    
    # Обновляем .env файл
    if grep -q "^POSTGRES_PASSWORD=" "$ENV_FILE"; then
        sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" "$ENV_FILE"
    else
        echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> "$ENV_FILE"
    fi
else
    echo -e "${GREEN}✓ POSTGRES_PASSWORD уже настроен${NC}"
fi

# Генерация JWT_SECRET
if [ -z "$JWT_SECRET" ] || [ "$JWT_SECRET" = "your-super-secret-jwt-token-with-at-least-32-characters-long-change-me" ]; then
    JWT_SECRET=$(generate_secret)
    echo -e "${GREEN}✓ Сгенерирован JWT_SECRET${NC}"
    
    # Обновляем .env файл
    if grep -q "^JWT_SECRET=" "$ENV_FILE"; then
        sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" "$ENV_FILE"
    else
        echo "JWT_SECRET=$JWT_SECRET" >> "$ENV_FILE"
    fi
else
    echo -e "${GREEN}✓ JWT_SECRET уже настроен${NC}"
fi

# Перезагружаем переменные
source "$ENV_FILE" 2>/dev/null || true

# Шаг 3: Генерация JWT токенов
echo ""
echo "3. Генерация JWT токенов..."

ANON_KEY=$(generate_jwt_token "anon" "$JWT_SECRET")
SERVICE_KEY=$(generate_jwt_token "service_role" "$JWT_SECRET")

echo -e "${GREEN}✓ Сгенерирован SUPABASE_ANON_KEY${NC}"
echo -e "${GREEN}✓ Сгенерирован SUPABASE_SERVICE_KEY${NC}"

# Шаг 4: Обновление .env файла с Supabase настройками
echo ""
echo "4. Обновление .env файла..."

# Определяем IP сервера для подключения
SERVER_IP=$(hostname -I | awk '{print $1}' || echo "localhost")
SUPABASE_URL="http://${SERVER_IP}:5432"

# Обновляем SUPABASE_URL
if grep -q "^SUPABASE_URL=" "$ENV_FILE"; then
    sed -i "s|^SUPABASE_URL=.*|SUPABASE_URL=$SUPABASE_URL|" "$ENV_FILE"
else
    echo "SUPABASE_URL=$SUPABASE_URL" >> "$ENV_FILE"
fi

# Обновляем SUPABASE_ANON_KEY
if grep -q "^SUPABASE_ANON_KEY=" "$ENV_FILE"; then
    sed -i "s|^SUPABASE_ANON_KEY=.*|SUPABASE_ANON_KEY=$ANON_KEY|" "$ENV_FILE"
else
    echo "SUPABASE_ANON_KEY=$ANON_KEY" >> "$ENV_FILE"
fi

# Обновляем SUPABASE_SERVICE_KEY
if grep -q "^SUPABASE_SERVICE_KEY=" "$ENV_FILE"; then
    sed -i "s|^SUPABASE_SERVICE_KEY=.*|SUPABASE_SERVICE_KEY=$SERVICE_KEY|" "$ENV_FILE"
else
    echo "SUPABASE_SERVICE_KEY=$SERVICE_KEY" >> "$ENV_FILE"
fi

# Устанавливаем SUPABASE_BUCKET если его нет
if ! grep -q "^SUPABASE_BUCKET=" "$ENV_FILE"; then
    echo "SUPABASE_BUCKET=portfolio" >> "$ENV_FILE"
fi

echo -e "${GREEN}✓ .env файл обновлен${NC}"

# Шаг 5: Запуск контейнера Supabase
echo ""
echo "5. Запуск контейнера Supabase..."

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Файл $COMPOSE_FILE не найден${NC}"
    exit 1
fi

# Останавливаем существующий контейнер если запущен
if docker ps -a --format '{{.Names}}' | grep -q "mediavelichie-supabase-db"; then
    echo "Останавливаем существующий контейнер..."
    docker compose -f "$COMPOSE_FILE" stop supabase 2>/dev/null || true
fi

# Запускаем только контейнер Supabase
echo "Запуск контейнера Supabase..."
docker compose -f "$COMPOSE_FILE" up -d supabase

# Шаг 6: Ожидание готовности
echo ""
echo "6. Ожидание готовности Supabase..."
echo "Это может занять 30-60 секунд..."

MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if docker exec mediavelichie-supabase-db pg_isready -U postgres &> /dev/null 2>&1; then
        echo -e "${GREEN}✓ Supabase готов!${NC}"
        break
    fi
    echo -n "."
    sleep 2
    WAITED=$((WAITED + 2))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "\n${YELLOW}⚠ Превышено время ожидания, но продолжаем...${NC}"
fi

# Шаг 7: Проверка статуса
echo ""
echo "7. Проверка статуса контейнера..."
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' mediavelichie-supabase-db 2>/dev/null || echo "unknown")

if [ "$CONTAINER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Контейнер Supabase запущен${NC}"
    
    # Получаем порт
    PORT=$(docker port mediavelichie-supabase-db 2>/dev/null | grep "5432" | cut -d: -f2 || echo "5432")
    echo -e "${GREEN}  Порт PostgreSQL: $PORT${NC}"
else
    echo -e "${RED}✗ Контейнер Supabase не запущен (статус: $CONTAINER_STATUS)${NC}"
    echo "Проверьте логи: docker logs mediavelichie-supabase-db"
    exit 1
fi

# Итоговая информация
echo ""
echo "=========================================="
echo "Установка завершена!"
echo "=========================================="
echo ""
echo -e "${BLUE}Данные для подключения к Supabase:${NC}"
echo ""
echo "SUPABASE_URL=$SUPABASE_URL"
echo "SUPABASE_ANON_KEY=$ANON_KEY"
echo "SUPABASE_SERVICE_KEY=$SERVICE_KEY"
echo ""
echo -e "${BLUE}Подключение к базе данных:${NC}"
echo "Host: $SERVER_IP"
echo "Port: $PORT"
echo "Database: postgres"
echo "User: postgres"
echo "Password: $POSTGRES_PASSWORD"
echo ""
echo -e "${BLUE}Полезные команды:${NC}"
echo "  Проверка статуса: docker ps | grep supabase"
echo "  Просмотр логов: docker logs mediavelichie-supabase-db"
echo "  Остановка: docker compose -f $COMPOSE_FILE stop supabase"
echo "  Запуск: docker compose -f $COMPOSE_FILE start supabase"
echo ""
echo -e "${GREEN}Все данные сохранены в файле: $ENV_FILE${NC}"
echo ""
