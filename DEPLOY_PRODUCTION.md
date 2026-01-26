# Автоматический деплой на боевой сервер

## Варианты автоматизации

### 1. GitHub Actions + SSH (Рекомендуется)

Автоматический деплой при каждом push в ветку `main` через SSH.

**Что нужно настроить:**

#### Шаг 1: Подготовка сервера

1. Убедитесь, что на сервере установлен SSH
2. Создайте пользователя для деплоя (или используйте существующего)
3. Настройте права доступа к директории сайта

#### Шаг 2: Настройка SSH ключа

**Вариант A: Использование существующего SSH ключа**

1. Если у вас уже есть SSH ключ на локальной машине:
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```
2. Скопируйте публичный ключ и добавьте на сервер:
   ```bash
   ssh-copy-id user@your-server.com
   ```

**Вариант B: Создание нового ключа для GitHub Actions**

1. Создайте новый SSH ключ:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github_actions_key
   ```
2. Добавьте публичный ключ на сервер:
   ```bash
   ssh-copy-id -i ~/.ssh/github_actions_key.pub user@your-server.com
   ```
3. Приватный ключ нужно будет добавить в GitHub Secrets

#### Шаг 3: Настройка GitHub Secrets

В репозитории GitHub:
1. Settings → Secrets and variables → Actions
2. Добавьте следующие секреты:

   - `SERVER_HOST` - IP адрес или домен сервера (например: `123.45.67.89` или `server.example.com`)
   - `SERVER_USER` - имя пользователя для SSH (например: `root` или `deploy`)
   - `SERVER_SSH_KEY` - приватный SSH ключ (весь файл ключа, включая `-----BEGIN RSA PRIVATE KEY-----`)
   - `SERVER_PORT` - порт SSH (обычно `22`, если не изменен)
   - `SERVER_PATH` - путь к директории сайта на сервере (например: `/var/www/html` или `/home/user/public_html`)

#### Шаг 4: Активация

После добавления секретов, каждый `git push` в ветку `main` будет автоматически деплоить код на сервер.

---

### 2. Git Hooks на сервере (Альтернатива)

Автоматический деплой через Git hooks прямо на сервере.

**Настройка:**

1. На сервере создайте bare репозиторий:
   ```bash
   cd /var/repos
   git init --bare mediavelichie.git
   ```

2. Создайте post-receive hook:
   ```bash
   cd /var/repos/mediavelichie.git/hooks
   nano post-receive
   ```

3. Добавьте в файл:
   ```bash
   #!/bin/bash
   TARGET="/var/www/html"
   GIT_DIR="/var/repos/mediavelichie.git"
   BRANCH="main"
   
   while read oldrev newrev refname
   do
       if [[ $refname = "refs/heads/$BRANCH" ]]
       then
           echo "Deploying $BRANCH branch to $TARGET..."
           git --work-tree=$TARGET --git-dir=$GIT_DIR checkout -f $BRANCH
           echo "Deployment completed!"
       fi
   done
   ```

4. Сделайте файл исполняемым:
   ```bash
   chmod +x post-receive
   ```

5. Добавьте remote в локальный репозиторий:
   ```bash
   git remote add production user@your-server.com:/var/repos/mediavelichie.git
   ```

6. При push:
   ```bash
   git push production main
   ```

---

### 3. Rsync через SSH (Простой вариант)

Использование rsync для синхронизации файлов.

**GitHub Actions workflow:**

```yaml
name: Deploy via Rsync

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy via rsync
        uses: burnett01/rsync-deployments@7.0.1
        with:
          switches: -avzr --delete
          path: ./
          remote_path: ${{ secrets.SERVER_PATH }}
          remote_host: ${{ secrets.SERVER_HOST }}
          remote_user: ${{ secrets.SERVER_USER }}
          remote_key: ${{ secrets.SERVER_SSH_KEY }}
```

---

## Примеры конфигурации для разных серверов

### Nginx + PHP-FPM

После деплоя может потребоваться перезагрузка:
```bash
sudo systemctl reload nginx
sudo systemctl reload php-fpm
```

### Apache

```bash
sudo systemctl reload apache2
# или
sudo service apache2 reload
```

### Node.js приложение (PM2)

```bash
cd /var/www/html
pm2 restart app
```

---

## Безопасность

1. **Используйте отдельного пользователя для деплоя** (не root)
2. **Ограничьте права SSH ключа** на сервере
3. **Используйте GitHub Secrets** для хранения чувствительных данных
4. **Настройте firewall** для ограничения доступа
5. **Используйте нестандартный SSH порт** (опционально)

---

## Требуемая информация от вас

Для настройки автоматического деплоя мне нужны:

1. **Тип сервера**: VPS, выделенный сервер, shared hosting?
2. **Операционная система**: Linux (какая дистрибуция?), Windows?
3. **Веб-сервер**: Nginx, Apache, другой?
4. **Доступ**: SSH доступен? Какой пользователь?
5. **Путь к сайту**: Где находится директория сайта? (например: `/var/www/html`)
6. **Доменное имя**: Есть ли домен? Нужна ли настройка DNS?

После получения этой информации я помогу настроить автоматический деплой под ваш конкретный случай.
