#!/bin/bash

# Безопасный скрипт для настройки SSH ключей
# Использование: ./setup-ssh-keys-safe.sh
# Пароль можно указать через переменную: SERVER_PASSWORD=yourpass ./setup-ssh-keys-safe.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Параметры сервера
SERVER_IP="194.58.88.127"
SERVER_USER="root"
SSH_KEY_NAME="mediavelichia_server"
SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"

# Получаем пароль из переменной окружения или запрашиваем
if [ -z "$SERVER_PASSWORD" ]; then
    echo -n "Enter server password: "
    read -s SERVER_PASSWORD
    echo ""
fi

echo "=========================================="
echo -e "${CYAN}SSH Key Setup${NC}"
echo "=========================================="
echo ""

# Проверяем наличие ssh-keygen
if ! command -v ssh-keygen &> /dev/null; then
    echo -e "${RED}Error: ssh-keygen not found${NC}"
    exit 1
fi

# Создаем директорию .ssh если не существует
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Генерируем SSH ключ если не существует
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${BLUE}Generating SSH key...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "mediavelichia-server-key"
    echo -e "${GREEN}✓ SSH key generated${NC}"
else
    echo -e "${YELLOW}SSH key already exists: $SSH_KEY_PATH${NC}"
fi

echo ""

# Копируем публичный ключ на сервер
echo -e "${BLUE}Copying public key to server...${NC}"

# Проверяем наличие sshpass
if command -v sshpass &> /dev/null; then
    sshpass -p "$SERVER_PASSWORD" ssh-copy-id -i "${SSH_KEY_PATH}.pub" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        ${SERVER_USER}@${SERVER_IP}
else
    echo -e "${YELLOW}sshpass not found. Please copy key manually:${NC}"
    echo "  ssh-copy-id -i ${SSH_KEY_PATH}.pub ${SERVER_USER}@${SERVER_IP}"
    echo "  Or manually:"
    echo "    cat ${SSH_KEY_PATH}.pub | ssh ${SERVER_USER}@${SERVER_IP} 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Public key copied to server${NC}"
else
    echo -e "${RED}✗ Failed to copy public key${NC}"
    exit 1
fi

echo ""

# Тестируем подключение без пароля
echo -e "${BLUE}Testing SSH connection...${NC}"
if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no \
    -o ConnectTimeout=5 \
    ${SERVER_USER}@${SERVER_IP} "echo 'SSH key authentication works!'" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH key authentication successful!${NC}"
else
    echo -e "${YELLOW}⚠ SSH key authentication test failed, but key may be copied${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}SSH Key Setup Complete!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Usage:${NC}"
echo "  ssh -i $SSH_KEY_PATH ${SERVER_USER}@${SERVER_IP}"
echo ""
