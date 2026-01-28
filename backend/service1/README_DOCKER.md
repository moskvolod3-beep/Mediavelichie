# Запуск Flask сервера в Docker

## Проблема с монтированием файлов

Если вы получаете ошибку:
```
error mounting "/run/desktop/mnt/host/d/Mediavelichia/editor/app.py" to rootfs at "/app/app.py": not a directory
```

Это означает, что Docker пытается смонтировать файл неправильно. Проблема решена в обновленном `docker-compose.yml`.

## Правильный запуск

### Важно: Запускайте из правильной директории!

```bash
# Перейдите в директорию сервиса
cd backend/service1

# Запустите Docker Compose
docker-compose up --build
```

### Или из корня проекта:

```bash
# Из корня проекта
cd backend/service1
docker-compose -f docker-compose.yml up --build
```

## Что было исправлено

1. **Монтирование всей директории** вместо отдельного файла `app.py`
   - Было: `- ./app.py:/app/app.py` (монтирует только файл)
   - Стало: `- .:/app` (монтирует всю директорию)

2. **Использование именованного volume для temp**
   - Временные файлы теперь хранятся в Docker volume, а не на хосте

## Структура volumes

```yaml
volumes:
  - .:/app                    # Вся директория проекта
  - temp-data:/app/temp        # Временные файлы в Docker volume
  - /app/__pycache__          # Исключаем кеш Python
  - /app/.pytest_cache        # Исключаем кеш тестов
```

## Проверка

После запуска проверьте:

```bash
# Проверьте, что контейнер запущен
docker ps

# Проверьте логи
docker-compose logs -f

# Проверьте, что Flask работает
curl http://localhost:5000
```

## Если проблема сохраняется

1. **Остановите все контейнеры:**
   ```bash
   docker-compose down
   ```

2. **Удалите старые volumes (если нужно):**
   ```bash
   docker-compose down -v
   ```

3. **Пересоберите образ:**
   ```bash
   docker-compose build --no-cache
   ```

4. **Запустите заново:**
   ```bash
   docker-compose up
   ```

## Для продакшена

Для продакшена рекомендуется использовать Dockerfile без volumes для монтирования кода - код должен быть скопирован в образ при сборке.
