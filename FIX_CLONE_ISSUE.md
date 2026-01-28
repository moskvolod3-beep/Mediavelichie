# Решение проблемы с клонированием репозитория

## Проблема

При попытке клонировать репозиторий в `/opt/mediavelichia` возникает ошибка:
```
fatal: destination path '.' already exists and is not an empty directory.
```

Это происходит потому, что директория уже существует и содержит файлы (например, `.env`).

## Решение

У вас есть два варианта:

### Вариант 1: Инициализировать Git в существующей директории (рекомендуется)

Если в директории уже есть важные файлы (например, `.env`), лучше инициализировать Git и добавить remote:

```bash
cd /opt/mediavelichia

# Инициализируем Git репозиторий
git init

# Добавляем remote
git remote add origin https://github.com/moskvolod3-beep/Mediavelichie.git

# Получаем код из репозитория
git fetch origin

# Переключаемся на ветку main
git checkout -b main origin/main

# Или если хотите перезаписать локальные файлы (кроме .env)
git reset --hard origin/main
```

**Важно:** Этот вариант сохранит ваш файл `.env` и другие локальные файлы.

### Вариант 2: Очистить директорию и клонировать заново

Если вы хотите полностью перезаписать содержимое:

```bash
# Переходим в родительскую директорию
cd /opt

# Сохраняем важные файлы (например, .env)
cp -r mediavelichia/.env /tmp/.env.backup 2>/dev/null || true

# Удаляем директорию проекта
rm -rf mediavelichia

# Клонируем репозиторий
git clone https://github.com/moskvolod3-beep/Mediavelichie.git mediavelichia

# Восстанавливаем .env файл
cp /tmp/.env.backup mediavelichia/.env 2>/dev/null || true

# Переходим в директорию проекта
cd mediavelichia
```

### Вариант 3: Использовать скрипт быстрого исправления

Скачайте и запустите скрипт:

```bash
cd /opt/mediavelichia
curl -o QUICK_FIX.sh https://raw.githubusercontent.com/moskvolod3-beep/Mediavelichie/main/QUICK_FIX.sh
chmod +x QUICK_FIX.sh
./QUICK_FIX.sh
```

## Проверка после клонирования

После успешного клонирования проверьте:

```bash
cd /opt/mediavelichia

# Проверка Git статуса
git status

# Проверка наличия файлов
ls -la

# Проверка наличия .env (если он нужен)
ls -la .env
```

## Следующие шаги

После успешного клонирования:

1. **Создайте или проверьте файл `.env`:**
```bash
# Если .env не существует, создайте из примера
if [ ! -f .env ]; then
    cp .env.example .env
    nano .env  # Заполните реальными значениями
fi
```

2. **Запустите Docker контейнеры:**
```bash
# Для облачного Supabase
docker compose -f docker-compose.prod.cloud.yml up -d --build

# Или для локального Supabase
docker compose -f docker-compose.prod.yml up -d --build
```

3. **Проверьте статус:**
```bash
docker compose -f docker-compose.prod.cloud.yml ps
```

## Обновление проекта в будущем

После первого клонирования для обновления используйте:

```bash
cd /opt/mediavelichia
git pull origin main
docker compose -f docker-compose.prod.cloud.yml up -d --build
```
