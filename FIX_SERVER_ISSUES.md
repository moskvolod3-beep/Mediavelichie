# Исправление проблем на сервере

## Проблема 1: unzip: command not found

**Ошибка:** `./rebuild-images-on-server.sh: line 70: unzip: command not found`

**Причина:** На сервере не установлен пакет `unzip`, который нужен для распаковки `.zip` файлов.

**Решение:** Скрипт `rebuild-images-on-server.sh` теперь автоматически устанавливает `unzip`, но вы можете установить его вручную:

```bash
# Debian/Ubuntu
apt-get update && apt-get install -y unzip

# CentOS/RHEL
yum install -y unzip

# Alpine
apk add unzip
```

**Альтернатива:** Используйте экспорт в формате `.tar.gz` вместо `.zip`. Скрипт `export-docker-images.ps1` теперь предпочитает gzip.

## Проблема 2: Синтаксическая ошибка в import-images.sh

**Ошибка:** `./import-images.sh: line 20: syntax error near unexpected token '2'`

**Решение:** Скрипт `import-images.sh` будет автоматически исправлен при следующем экспорте образов. Но вы можете использовать более надежный скрипт `rebuild-images-on-server.sh`.

## Проблема 3: Git remote 'github' не найден

**Ошибка:** `fatal: 'github' does not appear to be a git repository`

**Решение:** Используйте скрипт `fix-git-remote.sh` для автоматического исправления:

```bash
# На сервере
cd /opt/mediavelichia

# Скачайте последнюю версию скрипта (если еще не скачали)
git pull origin main
# или если origin не настроен:
git fetch origin
git checkout main

# Сделайте скрипт исполняемым
chmod +x fix-git-remote.sh

# Запустите исправление
./fix-git-remote.sh
```

Скрипт автоматически:
- Проверит существующие Git remotes
- Создаст или исправит remote 'github'
- Протестирует подключение

## Быстрое решение (все сразу)

```bash
# 1. Установить unzip (если еще не установлен)
apt-get update && apt-get install -y unzip

# 2. Исправить Git remote
cd /opt/mediavelichia
git pull origin main 2>/dev/null || git fetch origin
chmod +x fix-git-remote.sh
./fix-git-remote.sh

# 3. Использовать rebuild-images-on-server.sh (автоматически установит unzip если нужно)
chmod +x rebuild-images-on-server.sh
./rebuild-images-on-server.sh
```

## Альтернативное решение Git remote (вручную)

Если скрипт не работает, исправьте вручную:

```bash
cd /opt/mediavelichia

# Проверьте текущие remotes
git remote -v

# Если есть 'origin' с GitHub URL, создайте alias:
git remote add github $(git remote get-url origin)

# Или установите URL напрямую:
git remote add github https://github.com/moskvolod3-beep/Mediavelichie.git

# Проверьте:
git remote -v
git pull github main
```

## Использование rebuild-images-on-server.sh

Этот скрипт заменяет `import-images.sh` и делает все автоматически:

```bash
cd /opt/mediavelichia
chmod +x rebuild-images-on-server.sh
./rebuild-images-on-server.sh
```

Он:
1. Импортирует все образы из `/opt/mediavelichia/docker-images-import/`
2. Останавливает существующие контейнеры
3. Пересобирает контейнеры
4. Запускает их заново
5. Показывает статус
