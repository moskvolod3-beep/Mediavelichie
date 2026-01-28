# Перенос Docker образов на сервер

## Быстрый старт

### На локальном компьютере (Windows):

```powershell
# Запустите PowerShell скрипт
.\export-docker-images.ps1
```

Или если используете Git Bash / WSL:

```bash
chmod +x export-docker-images.sh
./export-docker-images.sh
```

### Передача файлов на сервер:

```bash
# Через SCP (из Git Bash или WSL)
scp -r docker-images-export/* root@194.58.88.127:/opt/mediavelichia/docker-images-import/

# Или используйте WinSCP / FileZilla для графического интерфейса
```

### На сервере:

**Вариант 1: Полная пересборка (рекомендуется)**

```bash
cd /opt/mediavelichia
chmod +x rebuild-images-on-server.sh
./rebuild-images-on-server.sh
```

Этот скрипт автоматически:
- Импортирует все образы из `/opt/mediavelichia/docker-images-import/`
- Останавливает существующие контейнеры
- Пересобирает контейнеры
- Запускает их заново

**Вариант 2: Только импорт образов**

```bash
cd /opt/mediavelichia/docker-images-import
chmod +x import-images.sh
./import-images.sh
```

Затем вручную пересоберите контейнеры:

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

## Подробная инструкция

### Шаг 1: Экспорт образов на локальном компьютере

Скрипт автоматически:
1. Соберет все необходимые образы из `docker-compose.prod.yml`
2. Экспортирует их в файлы `.tar.gz`
3. Создаст скрипт для импорта на сервере
4. Создаст README с инструкциями

**Результат:** Директория `docker-images-export/` с файлами образов

### Шаг 2: Передача файлов на сервер

#### Вариант A: Через SCP (командная строка)

```bash
# Создайте директорию на сервере
ssh root@194.58.88.127 "mkdir -p /opt/mediavelichia/docker-images-import"

# Передайте файлы
scp -r docker-images-export/* root@194.58.88.127:/opt/mediavelichia/docker-images-import/
```

#### Вариант B: Через WinSCP (графический интерфейс)

1. Откройте WinSCP
2. Подключитесь к серверу:
   - Host: `194.58.88.127`
   - User: `root`
   - Password: ваш пароль
3. Перейдите в `/opt/mediavelichia/docker-images-import/`
4. Скопируйте все файлы из `docker-images-export/`

#### Вариант C: Через FileZilla

Аналогично WinSCP, используйте SFTP протокол.

### Шаг 3: Импорт и пересборка образов на сервере

**Рекомендуемый способ (автоматическая пересборка):**

```bash
# Подключитесь к серверу
ssh root@194.58.88.127

# Перейдите в директорию проекта
cd /opt/mediavelichia

# Сделайте скрипт исполняемым (если еще не сделано)
chmod +x rebuild-images-on-server.sh

# Запустите пересборку
./rebuild-images-on-server.sh
```

Скрипт `rebuild-images-on-server.sh` автоматически:
- Импортирует все образы из `/opt/mediavelichia/docker-images-import/` (поддерживает `.tar`, `.tar.gz`, `.tar.zip`)
- Останавливает существующие контейнеры
- Пересобирает контейнеры через Docker Compose
- Запускает контейнеры заново
- Показывает статус всех контейнеров

**Альтернативный способ (только импорт):**

```bash
# Перейдите в директорию с файлами
cd /opt/mediavelichia/docker-images-import

# Сделайте скрипт исполняемым
chmod +x import-images.sh

# Запустите импорт
./import-images.sh
```

Затем вручную пересоберите контейнеры:

```bash
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

### Шаг 4: Проверка и запуск

```bash
# Проверьте что образы импортированы
docker images | grep -E "mediavelichie|supabase"

# Запустите контейнеры
cd /opt/mediavelichia
docker compose -f docker-compose.prod.yml up -d

# Проверьте статус
docker ps
```

## Альтернативные методы

### Метод 1: Docker Registry (рекомендуется для частых обновлений)

Если вы часто обновляете образы, лучше использовать Docker Hub или приватный registry:

```bash
# На локальном компьютере
docker tag mediavelichie-web:latest your-dockerhub-username/mediavelichie-web:latest
docker push your-dockerhub-username/mediavelichie-web:latest

# На сервере
docker pull your-dockerhub-username/mediavelichie-web:latest
```

### Метод 2: Прямой экспорт через docker save (без скрипта)

```bash
# На локальном компьютере
docker save mediavelichie-web:latest -o web-image.tar
gzip web-image.tar

# Передача
scp web-image.tar.gz root@194.58.88.127:/tmp/

# На сервере
gunzip -c /tmp/web-image.tar.gz | docker load
```

### Метод 3: Использование docker-compose на сервере

Если на сервере есть доступ к исходному коду, можно собрать образы напрямую:

```bash
cd /opt/mediavelichia
git pull origin main
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

## Размеры файлов

Ожидаемые размеры экспортированных образов:

- `mediavelichie-web`: ~50-100 MB
- `mediavelichie-editor`: ~200-500 MB
- `supabase/postgres:15.1.0.117`: ~300-400 MB
- `supabase/studio:latest`: ~200-300 MB

**Общий размер:** ~1-2 GB (после сжатия ~500-800 MB)

## Устранение проблем

### Ошибка: "No space left on device"

```bash
# Проверьте свободное место на сервере
df -h

# Очистите неиспользуемые образы
docker system prune -a

# Или удалите старые образы перед импортом
docker images | grep -E "mediavelichie|supabase" | awk '{print $3}' | xargs docker rmi
```

### Ошибка: "gzip: command not found"

Если на сервере нет gzip, используйте альтернативный метод:

```bash
# Импорт без распаковки (если файлы не сжаты)
for FILE in *.tar; do
    docker load -i "$FILE"
done
```

### Ошибка при передаче больших файлов

Используйте `rsync` вместо `scp` для более надежной передачи:

```bash
rsync -avz --progress docker-images-export/ root@194.58.88.127:/opt/mediavelichia/docker-images-import/
```

## Безопасность

⚠️ **Важно:**

1. Не передавайте файлы через незащищенные каналы
2. Используйте SSH ключи вместо паролей
3. Удалите экспортированные файлы после успешного импорта
4. Не коммитьте экспортированные образы в Git (они уже в `.gitignore`)

## Автоматизация

Для автоматической передачи можно создать скрипт:

```bash
#!/bin/bash
# transfer-images.sh

# Экспорт
./export-docker-images.sh

# Передача
scp -r docker-images-export/* root@194.58.88.127:/opt/mediavelichia/docker-images-import/

# Импорт на сервере
ssh root@194.58.88.127 "cd /opt/mediavelichia/docker-images-import && chmod +x import-images.sh && ./import-images.sh"
```
