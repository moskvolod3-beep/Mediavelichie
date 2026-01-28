# Шаблон для GitHub Secrets

**⚠️ ВАЖНО:** Этот файл является шаблоном и НЕ должен содержать реальные данные сервера!
Все значения ниже являются примерами и должны быть заменены на ваши реальные данные при настройке.

Используйте этот шаблон для настройки GitHub Secrets в репозитории.

## Настройка Secrets

1. Перейдите в **Settings** → **Secrets and variables** → **Actions**
2. Нажмите **New repository secret**
3. Добавьте следующие secrets:

### Обязательные Secrets:

```
SERVER_HOST = your-server-ip-address
SERVER_USER = your-ssh-username
SERVER_PORT = 22
SERVER_PATH = /opt/mediavelichia
```

**Пример:**
```
SERVER_HOST = 192.168.1.100
SERVER_USER = deploy
SERVER_PORT = 22
SERVER_PATH = /opt/mediavelichia
```

### SSH Key (рекомендуется):

**ВАЖНО:** Для безопасности используйте SSH ключ вместо пароля!

1. Сгенерируйте SSH ключ на локальной машине:
   ```bash
   ssh-keygen -t ed25519 -C "deploy@mediavelichia"
   ```

2. Скопируйте публичный ключ на сервер:
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub your-username@your-server-ip
   ```
   
   **Пример:**
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@192.168.1.100
   ```

3. Добавьте приватный ключ в GitHub Secrets:
   - Имя: `SERVER_SSH_KEY`
   - Значение: содержимое файла `~/.ssh/id_ed25519`

### Альтернатива (использование пароля - не рекомендуется):

Если вы не можете использовать SSH ключ, можно настроить SSH с паролем через `sshpass`, но это менее безопасно.

---

## Проверка настройки

После настройки secrets проверьте workflow:

1. Перейдите в **Actions**
2. Выберите **Deploy to Production Server**
3. Нажмите **Run workflow**
4. Проверьте логи выполнения

---

*Этот файл можно удалить после настройки secrets*
