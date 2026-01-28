# Быстрое решение Git конфликта

## Проблема

```
error: Your local changes to the following files would be overwritten by merge:
        fix-url-in-container.sh
Please commit your changes or stash them before you merge.
```

## Решение (выберите один вариант)

### Вариант 1: Отбросить локальные изменения (рекомендуется)

```bash
cd /opt/mediavelichia

# Отбросить локальные изменения в конфликтующем файле
git checkout -- fix-url-in-container.sh

# Теперь можно сделать pull
git pull origin main
```

### Вариант 2: Использовать скрипт автоматического исправления

```bash
cd /opt/mediavelichia

# Используйте скрипт для автоматического разрешения конфликта
chmod +x fix-git-conflicts.sh
./fix-git-conflicts.sh --use-remote
```

### Вариант 3: Сохранить изменения в stash

Если вы хотите сохранить локальные изменения:

```bash
cd /opt/mediavelichia

# Сохранить изменения
git stash push -m "Local changes to fix-url-in-container.sh"

# Сделать pull
git pull origin main

# Если нужно восстановить изменения позже:
# git stash pop
```

## После решения конфликта

```bash
# Сделайте скрипты исполняемыми
chmod +x fix-url-in-container.sh
chmod +x complete-url-fix.sh
chmod +x fix-supabase-url.sh

# Исправьте Supabase URL
./fix-url-in-container.sh https://ВАШ-РЕАЛЬНЫЙ-PROJECT-ID.supabase.co
```

## Быстрая команда (все сразу)

```bash
cd /opt/mediavelichia
git checkout -- fix-url-in-container.sh
git pull origin main
chmod +x fix-url-in-container.sh complete-url-fix.sh fix-supabase-url.sh
```
