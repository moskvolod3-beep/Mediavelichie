# Обновление Docker контейнеров Flask сервера

## Быстрая команда

```powershell
cd backend\service1
docker-compose down
docker-compose up -d --build
```

## Пошаговая инструкция

### 1. Остановить старые контейнеры

```powershell
cd backend\service1
docker-compose down
```

### 2. Пересобрать образы (опционально, если нужна полная пересборка)

```powershell
docker-compose build --no-cache
```

**Примечание:** Это может занять 5-10 минут из-за установки FFmpeg и зависимостей.

### 3. Запустить новые контейнеры

```powershell
docker-compose up -d
```

Или с автоматической пересборкой:

```powershell
docker-compose up -d --build
```

### 4. Проверить статус

```powershell
docker-compose ps
docker-compose logs -f
```

## Если контейнеры не запускаются

### Проверить логи ошибок:

```powershell
docker-compose logs editor
```

### Удалить старые volumes (если нужно):

```powershell
docker-compose down -v
docker-compose up -d --build
```

### Полная очистка и пересборка:

```powershell
docker-compose down -v
docker system prune -f
docker-compose build --no-cache
docker-compose up -d
```

## Проверка работы Flask сервера

После запуска проверьте:

```powershell
# Проверить, что контейнер запущен
docker ps

# Проверить логи
docker-compose logs -f editor

# Проверить доступность (в другом терминале)
curl http://localhost:5000
# или откройте в браузере: http://localhost:5000
```

## Исправленные проблемы

✅ Исправлено монтирование файлов - теперь монтируется вся директория вместо отдельного файла  
✅ Удален устаревший атрибут `version` из docker-compose.yml  
✅ Настроено правильное монтирование volumes для разработки
