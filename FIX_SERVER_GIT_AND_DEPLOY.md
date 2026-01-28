# Решение проблем с Git и развертыванием миграции на сервере

## Проблема 1: Git конфликт

На сервере есть незакоммиченные изменения, которые мешают выполнить `git pull`.

### Решение:

Выполните на сервере один из вариантов:

#### Вариант A: Сохранить изменения (если они важны)

```bash
cd /opt/mediavelichia

# Проверяем какие файлы изменены
git status

# Сохраняем изменения во временное хранилище
git stash

# Обновляем код
git pull origin main

# Если нужно восстановить сохраненные изменения:
# git stash pop
```

#### Вариант B: Отменить локальные изменения (если они не важны)

```bash
cd /opt/mediavelichia

# Проверяем какие файлы изменены
git status

# Отменяем все локальные изменения
git reset --hard HEAD

# Обновляем код
git pull origin main
```

#### Вариант C: Принудительное обновление (если уверены, что локальные изменения не нужны)

```bash
cd /opt/mediavelichia

# Принудительно обновляем до состояния удаленного репозитория
git fetch origin
git reset --hard origin/main
```

## Проблема 2: Скрипт deploy-migration.sh не найден

После успешного `git pull` скрипт должен появиться.

### Проверка:

```bash
cd /opt/mediavelichia

# Проверяем наличие скрипта
ls -la deploy-migration.sh

# Если скрипт есть, делаем его исполняемым
chmod +x deploy-migration.sh

# Проверяем содержимое директории миграций
ls -la backend/supabase/migrations/
```

## Полная последовательность действий на сервере:

```bash
cd /opt/mediavelichia

# 1. Решаем проблему с Git (выберите один из вариантов выше)
git reset --hard HEAD
git pull origin main

# 2. Проверяем наличие скрипта
ls -la deploy-migration.sh

# 3. Делаем скрипт исполняемым
chmod +x deploy-migration.sh

# 4. Проверяем наличие файла миграции
ls -la backend/supabase/migrations/20260128133013_full_schema_export.sql

# 5. Применяем миграцию
./deploy-migration.sh
```

## Альтернатива: Ручное применение миграции

Если скрипт все еще не работает, можно применить миграцию вручную:

```bash
cd /opt/mediavelichia

# Проверяем что контейнер запущен
docker ps | grep mediavelichie-supabase-db

# Применяем миграцию напрямую
docker exec -i mediavelichie-supabase-db psql -U postgres < backend/supabase/migrations/20260128133013_full_schema_export.sql
```

## Проверка результата

После применения миграции проверьте:

```bash
# Список таблиц
docker exec mediavelichie-supabase-db psql -U postgres -c "\dt"

# Список функций
docker exec mediavelichie-supabase-db psql -U postgres -c "\df"

# Проверка конкретной таблицы
docker exec mediavelichie-supabase-db psql -U postgres -c "\d+ orders"
```
