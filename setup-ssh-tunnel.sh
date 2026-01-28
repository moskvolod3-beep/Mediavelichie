#!/bin/bash

# Скрипт для настройки SSH туннеля к серверу
# Использование: ./setup-ssh-tunnel.sh [LOCAL_PORT] [REMOTE_PORT]

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

# Порты для туннеля
LOCAL_PORT="${1:-2222}"
REMOTE_PORT="${2:-22}"

echo "=========================================="
echo -e "${CYAN}SSH Tunnel Setup${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Server:${NC} $SERVER_USER@$SERVER_IP"
echo -e "${BLUE}Local port:${NC} $LOCAL_PORT"
echo -e "${BLUE}Remote port:${NC} $REMOTE_PORT"
echo ""

# Проверяем наличие sshpass (для автоматического ввода пароля)
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass not found. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y -q sshpass
    elif command -v brew &> /dev/null; then
        brew install hudochenkov/sshpass/sshpass
    else
        echo -e "${RED}Error: Cannot install sshpass automatically${NC}"
        echo "Please install sshpass manually or use SSH keys"
        exit 1
    fi
fi

echo -e "${BLUE}Setting up SSH tunnel...${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Tunnel will run in background"
echo "To stop tunnel: kill \$(ps aux | grep 'ssh.*$SERVER_IP' | grep -v grep | awk '{print \$2}')"
echo ""

# Создаем SSH туннель
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -N -L ${LOCAL_PORT}:localhost:${REMOTE_PORT} \
    ${SERVER_USER}@${SERVER_IP} &

TUNNEL_PID=$!

sleep 2

# Проверяем что туннель запущен
if ps -p $TUNNEL_PID > /dev/null; then
    echo -e "${GREEN}✓ SSH tunnel established!${NC}"
    echo ""
    echo -e "${BLUE}Tunnel details:${NC}"
    echo "  Local port: $LOCAL_PORT"
    echo "  Remote: localhost:$REMOTE_PORT"
    echo "  PID: $TUNNEL_PID"
    echo ""
    echo -e "${BLUE}Usage:${NC}"
    echo "  Connect via tunnel: ssh -p $LOCAL_PORT $SERVER_USER@localhost"
    echo "  Or use: ssh -p $LOCAL_PORT root@127.0.0.1"
    echo ""
    echo -e "${YELLOW}Security warning:${NC}"
    echo "  Password is stored in this script. Consider using SSH keys instead."
    echo ""
else
    echo -e "${RED}✗ Failed to establish tunnel${NC}"
    exit 1
fi
