# PowerShell скрипт для настройки SSH ключей на Windows
# Использование: .\setup-ssh-keys.ps1

$ErrorActionPreference = "Stop"

$SERVER_IP = "194.58.88.127"
$SERVER_USER = "root"
$SERVER_PASSWORD = "PT1QwG5ul4LXKH"
$SSH_KEY_NAME = "mediavelichia_server"
$SSH_KEY_PATH = "$env:USERPROFILE\.ssh\$SSH_KEY_NAME"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SSH Key Setup for Windows" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Проверяем наличие OpenSSH
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "Error: OpenSSH not found. Please install OpenSSH Client." -ForegroundColor Red
    Write-Host "Install via: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Yellow
    exit 1
}

# Создаем директорию .ssh если не существует
if (-not (Test-Path "$env:USERPROFILE\.ssh")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" -Force | Out-Null
    Write-Host "Created .ssh directory" -ForegroundColor Green
}

# Генерируем SSH ключ если не существует
if (-not (Test-Path $SSH_KEY_PATH)) {
    Write-Host "Generating SSH key..." -ForegroundColor Blue
    ssh-keygen -t rsa -b 4096 -f $SSH_KEY_PATH -N '""' -C "mediavelichia-server-key"
    Write-Host "SSH key generated" -ForegroundColor Green
} else {
    Write-Host "SSH key already exists: $SSH_KEY_PATH" -ForegroundColor Yellow
}

Write-Host ""

# Копируем публичный ключ на сервер
Write-Host "Copying public key to server..." -ForegroundColor Blue

# Читаем публичный ключ
$PUBLIC_KEY = Get-Content "$SSH_KEY_PATH.pub" -Raw

# Создаем временный скрипт для копирования ключа
$TEMP_SCRIPT = "$env:TEMP\copy_key.sh"
@"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
"@ | Out-File -FilePath $TEMP_SCRIPT -Encoding UTF8

# Используем sshpass или прямое подключение
Write-Host "Please enter password when prompted: $SERVER_PASSWORD" -ForegroundColor Yellow

# Пробуем скопировать ключ
$PUBLIC_KEY_CONTENT = Get-Content "$SSH_KEY_PATH.pub"
$PUBLIC_KEY_CONTENT | ssh "$SERVER_USER@$SERVER_IP" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Public key copied to server" -ForegroundColor Green
} else {
    Write-Host "Warning: Failed to copy key automatically. Copy manually:" -ForegroundColor Yellow
    Write-Host "  type $SSH_KEY_PATH.pub | ssh $SERVER_USER@$SERVER_IP `"cat >> ~/.ssh/authorized_keys`"" -ForegroundColor Yellow
}

Write-Host ""

# Тестируем подключение
Write-Host "Testing SSH connection..." -ForegroundColor Blue
$TEST_RESULT = ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$SERVER_USER@$SERVER_IP" "echo 'SSH key authentication works!'" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "SSH key authentication successful!" -ForegroundColor Green
} else {
    Write-Host "SSH key authentication test failed. You may need to copy key manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SSH Key Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Blue
Write-Host "  ssh -i $SSH_KEY_PATH ${SERVER_USER}@${SERVER_IP}" -ForegroundColor White
Write-Host ""
Write-Host "Or add to C:\Users\$env:USERNAME\.ssh\config:" -ForegroundColor Blue
Write-Host "Host mediavelichia" -ForegroundColor White
Write-Host "    HostName $SERVER_IP" -ForegroundColor White
Write-Host "    User $SERVER_USER" -ForegroundColor White
Write-Host "    IdentityFile $SSH_KEY_PATH" -ForegroundColor White
Write-Host ""
Write-Host "Then connect with: ssh mediavelichia" -ForegroundColor White
Write-Host ""
