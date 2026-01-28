# Настройка SSH подключения к серверу

## Параметры сервера

- **IP:** 194.58.88.127
- **Пользователь:** root
- **Пароль:** PT1QwG5ul4LXKH
- **Порт:** 22

## Вариант 1: Настройка SSH ключей (рекомендуется)

### На локальном компьютере (Windows):

#### Использование Git Bash или WSL:

```bash
# Перейдите в директорию проекта
cd /d/Mediavelichia

# Сделайте скрипт исполняемым
chmod +x setup-ssh-keys.sh

# Запустите настройку SSH ключей
./setup-ssh-keys.sh
```

Скрипт автоматически:
1. Создаст SSH ключ `~/.ssh/mediavelichia_server`
2. Скопирует публичный ключ на сервер
3. Настроит подключение без пароля

После настройки подключайтесь:
```bash
ssh -i ~/.ssh/mediavelichia_server root@194.58.88.127
```

#### Использование PowerShell:

```powershell
# Установите OpenSSH если еще не установлен
# (обычно уже установлен в Windows 10/11)

# Создайте SSH ключ
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\mediavelichia_server -N '""'

# Скопируйте ключ на сервер (потребуется ввести пароль один раз)
type $env:USERPROFILE\.ssh\mediavelichia_server.pub | ssh root@194.58.88.127 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Теперь подключайтесь без пароля
ssh -i $env:USERPROFILE\.ssh\mediavelichia_server root@194.58.88.127
```

### Настройка SSH config (опционально)

Создайте файл `~/.ssh/config` (или `C:\Users\ВашеИмя\.ssh\config` в Windows):

```
Host mediavelichia
    HostName 194.58.88.127
    User root
    IdentityFile ~/.ssh/mediavelichia_server
    Port 22
```

Теперь подключайтесь просто:
```bash
ssh mediavelichia
```

## Вариант 2: SSH туннель

Если нужно создать туннель для доступа к сервисам:

```bash
# Используйте скрипт
chmod +x setup-ssh-tunnel.sh
./setup-ssh-tunnel.sh [LOCAL_PORT] [REMOTE_PORT]

# Или вручную:
ssh -L 2222:localhost:22 root@194.58.88.127
```

## Вариант 3: Прямое подключение с паролем

### Windows PowerShell:

```powershell
ssh root@194.58.88.127
# Введите пароль: PT1QwG5ul4LXKH
```

### Git Bash / WSL:

```bash
ssh root@194.58.88.127
# Введите пароль: PT1QwG5ul4LXKH
```

### С автоматическим вводом пароля (требует sshpass):

```bash
# Установите sshpass (Linux/WSL/Git Bash)
# Ubuntu/Debian: sudo apt-get install sshpass
# macOS: brew install hudochenkov/sshpass/sshpass

sshpass -p 'PT1QwG5ul4LXKH' ssh root@194.58.88.127
```

## Безопасность

⚠️ **Важно:**

1. **Не коммитьте пароли в Git!** Файлы с паролями уже в `.gitignore`
2. **Используйте SSH ключи** вместо паролей для безопасности
3. **Ограничьте доступ** к серверу через firewall
4. **Измените пароль root** на более сложный

## Полезные команды

### Подключение к серверу:

```bash
# С ключом
ssh -i ~/.ssh/mediavelichia_server root@194.58.88.127

# С паролем
ssh root@194.58.88.127

# Через config
ssh mediavelichia
```

### Копирование файлов:

```bash
# С локального на сервер
scp -i ~/.ssh/mediavelichia_server file.txt root@194.58.88.127:/opt/mediavelichia/

# С сервера на локальный
scp -i ~/.ssh/mediavelichia_server root@194.58.88.127:/opt/mediavelichia/file.txt ./
```

### Выполнение команд на сервере:

```bash
ssh root@194.58.88.127 "cd /opt/mediavelichia && docker ps"
```

## Устранение проблем

### Ошибка "Permission denied"

1. Проверьте правильность пароля
2. Убедитесь что пользователь `root` может подключаться по SSH
3. Проверьте права на SSH ключ: `chmod 600 ~/.ssh/mediavelichia_server`

### Ошибка "Host key verification failed"

```bash
# Удалите старый ключ хоста
ssh-keygen -R 194.58.88.127

# Или добавьте в known_hosts
ssh-keyscan -H 194.58.88.127 >> ~/.ssh/known_hosts
```

### Ошибка "Connection refused"

1. Проверьте что сервер доступен: `ping 194.58.88.127`
2. Проверьте что порт 22 открыт: `telnet 194.58.88.127 22`
3. Проверьте firewall на сервере: `ufw status`

## Автоматизация

Для автоматического выполнения команд можно использовать:

```bash
# Создайте скрипт для быстрого подключения
cat > ~/connect-server.sh << 'EOF'
#!/bin/bash
ssh -i ~/.ssh/mediavelichia_server root@194.58.88.127 "$@"
EOF

chmod +x ~/connect-server.sh

# Использование:
~/connect-server.sh "docker ps"
```
