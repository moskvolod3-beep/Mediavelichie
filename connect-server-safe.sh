#!/bin/bash

# Безопасный скрипт для подключения к серверу
# Использование: ./connect-server-safe.sh [COMMAND]
# Пароль можно указать через переменную: SERVER_PASSWORD=yourpass ./connect-server-safe.sh

set -e

SERVER_IP="194.58.88.127"
SERVER_USER="root"
SSH_KEY_PATH="$HOME/.ssh/mediavelichia_server"

# Проверяем наличие SSH ключа
if [ -f "$SSH_KEY_PATH" ]; then
    # Используем SSH ключ
    if [ $# -gt 0 ]; then
        ssh -i "$SSH_KEY_PATH" ${SERVER_USER}@${SERVER_IP} "$@"
    else
        ssh -i "$SSH_KEY_PATH" ${SERVER_USER}@${SERVER_IP}
    fi
else
    # Используем пароль (запросит при подключении)
    echo "SSH key not found. Will use password authentication."
    echo "Password: (enter when prompted)"
    if [ $# -gt 0 ]; then
        ssh ${SERVER_USER}@${SERVER_IP} "$@"
    else
        ssh ${SERVER_USER}@${SERVER_IP}
    fi
fi
