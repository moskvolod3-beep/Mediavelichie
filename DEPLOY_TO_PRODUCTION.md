# Деплой на боевой сервер Supabase

## Подготовка

### 1. Убедитесь, что локальная разработка работает

```powershell
# Запустите локальный Supabase
supabase start

# Проверьте статус
supabase status

# Протестируйте работу сайта локально
```

### 2. Создайте проект на Supabase Cloud

1. Перейдите на https://supabase.com
2. Войдите в аккаунт или зарегистрируйтесь
3. Нажмите "New Project"
4. Заполните форму:
   - **Name**: Mediavelichia (или другое имя)
   - **Database Password**: создайте надежный пароль (сохраните его!)
   - **Region**: выберите ближайший регион к вашей аудитории
5. Нажмите "Create new project"
6. Дождитесь создания проекта (1-2 минуты)

### 3. Получите данные проекта

После создания проекта:

1. Перейдите в **Settings** → **API**
2. Скопируйте следующие значения:
   - **Project URL** (например: `https://xxxxx.supabase.co`)
   - **anon public** key
   - **service_role** key (для административных операций, храните в секрете!)

## Связывание локального проекта с удаленным

### Вариант А: Через Project Ref

1. Найдите Project Ref в URL проекта:
   - URL: `https://xxxxx.supabase.co`
   - Project Ref: `xxxxx` (часть перед `.supabase.co`)

2. Свяжите проекты:
```powershell
supabase link --project-ref xxxxx
```

Введите пароль базы данных, который вы создали при создании проекта.

### Вариант Б: Через Dashboard

1. В Supabase Dashboard перейдите в **Settings** → **General**
2. Найдите **Reference ID**
3. Используйте его для связывания:
```powershell
supabase link --project-ref YOUR_REFERENCE_ID
```

## Применение миграций на боевой сервер

### 1. Проверьте миграции

```powershell
# Просмотр всех миграций
Get-ChildItem supabase\migrations\

# Проверка статуса миграций
supabase migration list
```

### 2. Примените миграции

```powershell
# Применить все миграции на удаленный проект
supabase db push
```

Это применит все миграции из `supabase/migrations/` на боевой сервер.

### 3. Проверьте результат

1. Откройте Supabase Dashboard
2. Перейдите в **Table Editor**
3. Убедитесь, что все таблицы созданы:
   - `orders`
   - `portfolio`
   - `reviews`
   - `projects`
   - `project_videos`

## Обновление конфигурации для продакшена

### 1. Обновите config.js

Откройте `supabase/config.js` и замените значения:

```javascript
export const SUPABASE_CONFIG = {
    url: 'https://ВАШ_PROJECT_REF.supabase.co', // Project URL из Dashboard
    anonKey: 'ВАШ_ANON_KEY' // anon public key из Dashboard
};
```

### 2. Проверьте RLS политики

В Supabase Dashboard:
1. Перейдите в **Authentication** → **Policies**
2. Убедитесь, что политики безопасности применены:
   - Публичный доступ для чтения опубликованных данных
   - Создание заявок доступно всем
   - Управление данными только для авторизованных

## Добавление тестовых данных (опционально)

Если нужно добавить тестовые данные на боевой сервер:

1. Откройте Supabase Dashboard
2. Перейдите в **SQL Editor**
3. Скопируйте содержимое `supabase/migrations/20240115000001_sample_data.sql`
4. Выполните SQL

Или через CLI:
```powershell
supabase db execute -f supabase/migrations/20240115000001_sample_data.sql
```

## Настройка переменных окружения (для CI/CD)

Если используете CI/CD, создайте файл `.env.production`:

```env
SUPABASE_URL=https://ВАШ_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=ВАШ_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=ВАШ_SERVICE_ROLE_KEY
```

**ВАЖНО**: Не коммитьте `.env.production` в Git! Добавьте в `.gitignore`.

## Проверка работы

### 1. Проверьте API

```powershell
# Тест API через curl
curl "https://ВАШ_PROJECT_REF.supabase.co/rest/v1/orders?select=*" `
  -H "apikey: ВАШ_ANON_KEY" `
  -H "Authorization: Bearer ВАШ_ANON_KEY"
```

### 2. Проверьте сайт

1. Откройте сайт в браузере
2. Откройте консоль разработчика (F12)
3. Проверьте отсутствие ошибок подключения к Supabase
4. Попробуйте отправить форму заказа
5. Проверьте, что заявка появилась в таблице `orders` в Dashboard

## Резервное копирование

### Создание бэкапа

```powershell
# Экспорт схемы и данных
supabase db dump -f backup_$(Get-Date -Format "yyyyMMdd_HHmmss").sql
```

### Восстановление из бэкапа

```powershell
# Восстановление через SQL Editor в Dashboard
# Или через CLI (если настроен доступ)
supabase db execute -f backup.sql
```

## Обновление данных на продакшене

### Добавление новых миграций

1. Создайте новую миграцию локально:
```powershell
supabase migration new add_new_feature
```

2. Отредактируйте файл миграции в `supabase/migrations/`

3. Протестируйте локально:
```powershell
supabase db reset  # Применить все миграции заново
```

4. Примените на продакшене:
```powershell
supabase db push
```

### Обновление данных через Dashboard

1. Откройте Supabase Dashboard
2. Перейдите в **Table Editor**
3. Редактируйте данные напрямую

### Обновление данных через SQL

1. Откройте **SQL Editor** в Dashboard
2. Выполните SQL запросы

## Мониторинг и логи

### Просмотр логов

В Supabase Dashboard:
- **Logs** → **API Logs** - логи API запросов
- **Logs** → **Postgres Logs** - логи базы данных
- **Logs** → **Auth Logs** - логи аутентификации

### Метрики

В Dashboard доступны метрики:
- Количество запросов
- Использование базы данных
- Размер хранилища
- Активные соединения

## Безопасность

### Проверка безопасности

1. **RLS включен** для всех таблиц
2. **anon key** используется только на клиенте (публичный)
3. **service_role key** НИКОГДА не используется на клиенте!
4. Проверьте политики безопасности в **Authentication** → **Policies**

### Рекомендации

- Регулярно обновляйте пароль базы данных
- Используйте разные проекты для dev/staging/production
- Настройте уведомления о превышении лимитов
- Регулярно делайте резервные копии

## Откат изменений

Если нужно откатить миграцию:

```powershell
# Просмотр истории миграций
supabase migration list

# Откат через SQL Editor в Dashboard
# Выполните SQL для отката изменений вручную
```

## Troubleshooting

### Ошибки при применении миграций

1. Проверьте логи в Dashboard → **Logs**
2. Убедитесь, что миграции синтаксически корректны
3. Проверьте, что нет конфликтов с существующими данными

### Проблемы с подключением

1. Проверьте правильность URL и ключей в `config.js`
2. Убедитесь, что проект активен в Dashboard
3. Проверьте CORS настройки (если есть проблемы)

### Проблемы с RLS

1. Проверьте политики в **Authentication** → **Policies**
2. Убедитесь, что политики применены правильно
3. Проверьте, что `is_published = true` для публичных данных

## Дополнительные ресурсы

- [Документация Supabase](https://supabase.com/docs)
- [Управление окружениями](https://supabase.com/docs/guides/cli/managing-environments)
- [Миграции](https://supabase.com/docs/guides/cli/local-development#database-migrations)
- [Безопасность](https://supabase.com/docs/guides/auth/row-level-security)
