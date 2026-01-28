#!/bin/bash

# Скрипт для настройки SSH ключей (безопасная альтернатива паролю)
# Использование: ./setup-ssh-keys.sh

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
SERVER_PASSWORD="PT1QwG5ul4LXKH"

SSH_KEY_NAME="mediavelichia_server"
SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"

echo "=========================================="
echo -e "${CYAN}SSH Key Setup${NC}"
echo "=========================================="
echo ""

# Проверяем наличие ssh-keygen
if ! command -v ssh-keygen &> /dev/null; then
    echo -e "${RED}Error: ssh-keygen not found${NC}"
    exit 1
fi

# Проверяем наличие sshpass
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass not found. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y -q sshpass
    else
        echo -e "${RED}Error: Cannot install sshpass${NC}"
        exit 1
    fi
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
sshpass -p "$SERVER_PASSWORD" ssh-copy-id -i "${SSH_KEY_PATH}.pub" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ${SERVER_USER}@${SERVER_IP}

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
echo -e "${BLUE}Or add to ~/.ssh/config:${NC}"
echo "Host mediavelichia"
echo "    HostName $SERVER_IP"
echo "    User $SERVER_USER"
echo "    IdentityFile $SSH_KEY_PATH"
echo ""
echo "Then connect with: ssh mediavelichia"
echo ""
