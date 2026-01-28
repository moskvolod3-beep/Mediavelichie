# Быстрое подключение Supabase Studio

## Проблема
Studio на порту 3000 не видит PostgreSQL на порту 5432.

## Решение

### 1. Откройте Studio в браузере
```
http://194.58.88.127:3000
```

### 2. Заполните форму подключения

Когда Studio покажет форму "Connect to your project", заполните:

| Поле | Значение |
|------|----------|
| **Host** | `194.58.88.127` |
| **Port** | `5432` |
| **Database** | `postgres` |
| **User** | `postgres` |
| **Password** | `yNtGMC35GnqF8Od9PMZSDrKRR0I6jFJ2` |

### 3. Нажмите "Connect" или "Save"

После успешного подключения Studio сохранит эти данные и будет использовать их автоматически.

## Если не подключается

### Вариант 1: Используйте имя Docker сервиса
Если подключение с IP не работает, попробуйте:
- **Host:** `supabase` (вместо IP)

### Вариант 2: Проверьте доступность порта
```bash
# На сервере проверьте что порт открыт
nc -zv localhost 5432

# Или проверьте firewall
ufw status
```

### Вариант 3: Используйте Connection String
Вместо отдельных полей используйте Connection String:
```
postgresql://postgres:yNtGMC35GnqF8Od9PMZSDrKRR0I6jFJ2@194.58.88.127:5432/postgres
```

## Проверка подключения

После подключения вы должны увидеть:
- ✅ Список таблиц в разделе "Table Editor"
- ✅ Возможность выполнять SQL запросы
- ✅ Доступ к схеме базы данных

## Альтернатива: pgAdmin

Если Studio не работает, используйте pgAdmin (более стабильно):

```bash
# Добавьте в docker-compose.prod.yml и перезапустите
docker compose -f docker-compose.prod.yml up -d pgadmin
```

Доступ: http://194.58.88.127:5050
