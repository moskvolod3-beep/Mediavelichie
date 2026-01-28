# Быстрое решение Git конфликтов на сервере

## Проблема

```
error: Your local changes to the following files would be overwritten by merge:
        rebuild-images-on-server.sh
Please commit your changes or stash them before you merge.
```

## Решение (выберите один вариант)

### Вариант 1: Отбросить локальные изменения (рекомендуется)

```bash
cd /opt/mediavelichia
git reset --hard HEAD
git clean -fd
git pull origin main
```

Это отбросит все локальные изменения и использует версию из репозитория.

### Вариант 2: Использовать скрипт автоматического исправления

```bash
cd /opt/mediavelichia
git pull origin main  # Получите новый скрипт
chmod +x fix-git-conflicts.sh
./fix-git-conflicts.sh --use-remote
```

### Вариант 3: Сохранить локальные изменения в stash

Если вы хотите сохранить локальные изменения:

```bash
cd /opt/mediavelichia
git stash push -m "Local changes saved"
git pull origin main
# Если нужно восстановить изменения позже:
# git stash pop
```

### Вариант 4: Использовать обновленный fix-git-and-deploy.sh

```bash
cd /opt/mediavelichia
git fetch origin
git reset --hard origin/main  # Получить обновленный скрипт
chmod +x fix-git-and-deploy.sh
./fix-git-and-deploy.sh
```

## После решения конфликта

После успешного `git pull`:

```bash
# Сделайте скрипты исполняемыми
chmod +x restart-and-check.sh
chmod +x fix-git-conflicts.sh

# Запустите проверку
./restart-and-check.sh
```
