# PowerShell скрипт для быстрого подключения к серверу
# Использование: .\connect-server.ps1 [COMMAND]

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Command
)

$SERVER_IP = "194.58.88.127"
$SERVER_USER = "root"
$SERVER_PASSWORD = "PT1QwG5ul4LXKH"
$SSH_KEY_PATH = "$env:USERPROFILE\.ssh\mediavelichia_server"

# Проверяем наличие SSH ключа
if (Test-Path $SSH_KEY_PATH) {
    $SSH_CMD = "ssh -i `"$SSH_KEY_PATH`""
} else {
    $SSH_CMD = "ssh"
    Write-Host "SSH key not found, will use password authentication" -ForegroundColor Yellow
    Write-Host "Password: $SERVER_PASSWORD" -ForegroundColor Yellow
}

if ($Command.Count -gt 0) {
    # Выполняем команду на сервере
    $CMD_STRING = $Command -join " "
    Invoke-Expression "$SSH_CMD $SERVER_USER@$SERVER_IP `"$CMD_STRING`""
} else {
    # Интерактивное подключение
    Write-Host "Connecting to $SERVER_USER@$SERVER_IP..." -ForegroundColor Blue
    Write-Host "Password: $SERVER_PASSWORD" -ForegroundColor Yellow
    Invoke-Expression "$SSH_CMD $SERVER_USER@$SERVER_IP"
}
