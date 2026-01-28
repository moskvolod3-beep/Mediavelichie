# Быстрая настройка SSH подключения

## Параметры сервера

- **IP:** 194.58.88.127
- **Пользователь:** root
- **Пароль:** (см. локальные файлы)
- **Порт:** 22

## Быстрое подключение

### Windows PowerShell:

```powershell
# Прямое подключение
ssh root@194.58.88.127
# Введите пароль когда запросит

# Или создайте SSH ключ для безопасного подключения
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\mediavelichia_server -N '""'
type $env:USERPROFILE\.ssh\mediavelichia_server.pub | ssh root@194.58.88.127 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
ssh -i $env:USERPROFILE\.ssh\mediavelichia_server root@194.58.88.127
```

### Git Bash / WSL:

```bash
# Прямое подключение
ssh root@194.58.88.127
# Введите пароль когда запросит

# Или создайте SSH ключ
ssh-keygen -t rsa -b 4096 -f ~/.ssh/mediavelichia_server -N ""
ssh-copy-id -i ~/.ssh/mediavelichia_server.pub root@194.58.88.127
ssh -i ~/.ssh/mediavelichia_server root@194.58.88.127
```

## Настройка SSH config

Создайте файл `~/.ssh/config` (Windows: `C:\Users\ВашеИмя\.ssh\config`):

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

## Полезные команды

```bash
# Подключение
ssh root@194.58.88.127

# Выполнение команды на сервере
ssh root@194.58.88.127 "docker ps"

# Копирование файла на сервер
scp file.txt root@194.58.88.127:/opt/mediavelichia/

# Копирование файла с сервера
scp root@194.58.88.127:/opt/mediavelichia/file.txt ./
```

## Безопасность

⚠️ **Важно:**
- Используйте SSH ключи вместо паролей
- Не коммитьте файлы с паролями в Git
- Ограничьте доступ через firewall

Подробная инструкция: `SETUP_SSH.md`
