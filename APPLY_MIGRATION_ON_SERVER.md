# Инструкция по применению миграции на сервере

## Проблемы и решения

### Проблема 1: Git pull не работает из-за конфликта локальных изменений

**Ошибка:** `error: Your local changes to the following files would be overwritten by merge`

**Решение:** Отмените локальные изменения и обновите код:

```bash
cd /opt/mediavelichia

# Вариант 1: Используйте автоматический скрипт (рекомендуется)
chmod +x fix-git-and-deploy.sh
./fix-git-and-deploy.sh

# Вариант 2: Вручную отмените изменения и обновите код
git reset --hard HEAD
git pull origin main
```

**Если remote называется не "origin":**

Проверьте:
```bash
cd /opt/mediavelichia
git remote -v
```

Если видите `github`, используйте:
```bash
git reset --hard HEAD
git pull github main
```

### Проблема 2: Синтаксическая ошибка в скрипте

Если скрипт выдает ошибку синтаксиса, возможно проблема с кодировкой файла. Исправьте:

```bash
cd /opt/mediavelichia

# Обновите код
git pull origin main  # или git pull github main

# Проверьте синтаксис скрипта
bash -n deploy-migration.sh

# Если ошибка, пересоздайте скрипт с правильной кодировкой
# Или используйте прямое применение миграции (см. ниже)
```

## Быстрое решение: Прямое применение миграции

Если скрипт не работает, примените миграцию напрямую:

```bash
cd /opt/mediavelichia

# Обновите код (используйте правильный remote)
git remote -v  # Проверьте какой remote используется
git pull origin main  # или git pull github main

# Примените миграцию напрямую
docker exec -i mediavelichie-supabase-db psql -U postgres < backend/supabase/migrations/20260128133013_full_schema_export.sql
```

## Полная последовательность команд

### Быстрый способ (автоматический скрипт):

```bash
cd /opt/mediavelichia
chmod +x fix-git-and-deploy.sh
./fix-git-and-deploy.sh
# Затем примените миграцию:
./deploy-migration.sh
```

### Ручной способ:

```bash
cd /opt/mediavelichia

# 1. Решите конфликт Git (если есть)
git reset --hard HEAD

# 2. Проверьте remote
git remote -v

# 3. Обновите код (используйте правильный remote из шага 2)
git pull origin main
# ИЛИ
git pull github main

# 4. Проверьте наличие файла миграции
ls -la backend/supabase/migrations/20260128133013_full_schema_export.sql

# 5. Примените миграцию напрямую (самый надежный способ)
docker exec -i mediavelichie-supabase-db psql -U postgres < backend/supabase/migrations/20260128133013_full_schema_export.sql

# ИЛИ используйте скрипт (если он работает)
chmod +x deploy-migration.sh
./deploy-migration.sh
```

## Проверка результата

После применения миграции проверьте:

```bash
# Список таблиц
docker exec mediavelichie-supabase-db psql -U postgres -c "\dt"

# Проверка конкретной таблицы
docker exec mediavelichie-supabase-db psql -U postgres -c "\d+ orders"
docker exec mediavelichie-supabase-db psql -U postgres -c "\d+ portfolio"
docker exec mediavelichie-supabase-db psql -U postgres -c "\d+ projects"
```
