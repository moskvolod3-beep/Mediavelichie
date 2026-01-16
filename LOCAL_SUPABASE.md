# Локальная разработка с Supabase

## Требования

1. **Docker Desktop** - должен быть установлен и запущен
2. **Supabase CLI** - уже установлен через Scoop

## Быстрый старт

### 1. Запустите Docker Desktop

Убедитесь, что Docker Desktop запущен и работает. Проверить можно командой:
```powershell
docker ps
```

### 2. Запустите локальный Supabase

Выполните один из вариантов:

**Вариант А: Использовать скрипт**
```powershell
.\start-supabase-local.ps1
```

**Вариант Б: Вручную**
```powershell
supabase start
```

Это займет несколько минут при первом запуске (скачивание образов Docker).

### 3. Проверьте статус

```powershell
supabase status
```

Вы увидите информацию о локальных сервисах:
- API URL (обычно http://localhost:54321)
- GraphQL URL
- DB URL
- Studio URL (веб-интерфейс)
- anon key
- service_role key

### 4. Откройте Supabase Studio

В браузере откройте Studio URL (обычно http://localhost:54323)

Здесь вы можете:
- Просматривать и редактировать данные
- Выполнять SQL запросы
- Управлять таблицами
- Тестировать API

### 5. Примените миграции

Миграции уже находятся в папке `supabase/migrations/` и будут применены автоматически при запуске.

Если нужно применить миграции вручную:
```powershell
supabase db reset
```

## Обновление конфигурации для локальной разработки

После запуска `supabase start`, выполните:
```powershell
supabase status
```

Скопируйте значения и обновите `supabase/config.js`:

```javascript
export const SUPABASE_CONFIG = {
    url: 'http://localhost:54321', // Локальный API URL
    anonKey: 'ВАШ_ANON_KEY_ИЗ_STATUS' // anon key из статуса
};
```

Или создайте отдельный файл `supabase/config.local.js` для локальной разработки.

## Работа с данными

### Просмотр данных через Studio
1. Откройте Studio: http://localhost:54323
2. Перейдите в раздел "Table Editor"
3. Просматривайте и редактируйте данные

### Выполнение SQL
1. В Studio перейдите в "SQL Editor"
2. Выполняйте SQL запросы напрямую

### Через CLI
```powershell
# Выполнить SQL файл
supabase db execute -f supabase/migrations/your_migration.sql

# Сбросить базу данных (удалить все данные и применить миграции заново)
supabase db reset

# Создать резервную копию
supabase db dump -f backup.sql

# Восстановить из резервной копии
supabase db execute -f backup.sql
```

## Остановка локального Supabase

```powershell
supabase stop
```

Это остановит все контейнеры Docker, но не удалит данные.

Для полной очистки (удаление всех данных):
```powershell
supabase stop --no-backup
```

## Перенос на боевой сервер

### 1. Создайте проект на Supabase Cloud

1. Перейдите на https://supabase.com
2. Создайте новый проект
3. Дождитесь завершения создания (1-2 минуты)

### 2. Свяжите локальный проект с удаленным

```powershell
supabase link --project-ref YOUR_PROJECT_REF
```

`YOUR_PROJECT_REF` можно найти в URL проекта Supabase:
- URL: `https://xxxxx.supabase.co`
- Project Ref: `xxxxx`

### 3. Примените миграции на боевой сервер

```powershell
supabase db push
```

Это применит все миграции из `supabase/migrations/` на удаленный проект.

### 4. Обновите конфигурацию

Обновите `supabase/config.js` с данными из боевого проекта:
- Project URL из Dashboard
- anon key из Dashboard

### 5. (Опционально) Перенесите данные

Если нужно перенести данные из локальной БД:

```powershell
# Экспорт локальных данных
supabase db dump -f local_data.sql

# Импорт на боевой сервер (через Studio SQL Editor или CLI)
```

## Полезные команды

```powershell
# Статус локального Supabase
supabase status

# Просмотр логов
supabase logs

# Создать новую миграцию
supabase migration new migration_name

# Откатить последнюю миграцию
supabase migration repair --status reverted

# Генерация TypeScript типов из схемы БД
supabase gen types typescript --local > types/database.types.ts
```

## Troubleshooting

### Docker не запускается
- Убедитесь, что Docker Desktop установлен и запущен
- Проверьте, что виртуализация включена в BIOS

### Порт уже занят
Если порты 54321 или 54323 заняты, измените их в `supabase/config.toml`:
```toml
[api]
port = 54321

[studio]
port = 54323
```

### Ошибки при применении миграций
```powershell
# Сбросить базу и применить миграции заново
supabase db reset
```

### Очистка всего локального окружения
```powershell
supabase stop --no-backup
# Удалить папку .supabase если нужно полностью начать заново
```

## Дополнительные ресурсы

- [Документация Supabase CLI](https://supabase.com/docs/guides/cli)
- [Локальная разработка](https://supabase.com/docs/guides/cli/local-development)
- [Миграции](https://supabase.com/docs/guides/cli/managing-environments)
