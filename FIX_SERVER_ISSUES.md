# Исправление проблем на сервере

## Проблема 1: Синтаксическая ошибка в import-images.sh

**Ошибка:** `./import-images.sh: line 20: syntax error near unexpected token '2'`

**Решение:** Скрипт `import-images.sh` будет автоматически исправлен при следующем экспорте образов. Но вы можете использовать более надежный скрипт `rebuild-images-on-server.sh`.

## Проблема 2: Git remote 'github' не найден

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
# 1. Исправить Git remote
cd /opt/mediavelichia
git pull origin main 2>/dev/null || git fetch origin
chmod +x fix-git-remote.sh
./fix-git-remote.sh

# 2. Использовать rebuild-images-on-server.sh вместо import-images.sh
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
