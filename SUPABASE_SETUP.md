# Настройка Supabase для проекта Медиа Величия

Это руководство поможет вам настроить Supabase бекенд для проекта.

## Шаг 1: Создание проекта Supabase

1. Перейдите на [https://supabase.com](https://supabase.com)
2. Зарегистрируйтесь или войдите в аккаунт
3. Создайте новый проект:
   - Нажмите "New Project"
   - Выберите организацию или создайте новую
   - Введите название проекта (например, "mediavelichia")
   - Выберите регион (рекомендуется ближайший к вашей аудитории)
   - Введите пароль для базы данных
   - Дождитесь создания проекта (обычно 1-2 минуты)

## Шаг 2: Получение ключей доступа

1. В панели управления Supabase перейдите в **Settings** → **API**
2. Найдите секцию **Project API keys**
3. Скопируйте следующие значения:
   - **Project URL** (например: `https://xxxxx.supabase.co`)
   - **anon public** key (публичный ключ)

## Шаг 3: Настройка конфигурации

1. Откройте файл `supabase/config.js`
2. Замените значения:
   ```javascript
   export const SUPABASE_CONFIG = {
       url: 'ВАШ_PROJECT_URL', // Вставьте Project URL
       anonKey: 'ВАШ_ANON_KEY' // Вставьте anon public key
   };
   ```

## Шаг 4: Создание таблиц в базе данных

1. В панели Supabase перейдите в **SQL Editor**
2. Откройте файл `supabase/migrations/001_initial_schema.sql`
3. Скопируйте весь SQL код из файла
4. Вставьте в SQL Editor и нажмите **Run** (или F5)
5. Убедитесь, что все таблицы созданы успешно (проверьте вкладку **Table Editor**)

## Шаг 5: Добавление тестовых данных (опционально)

1. В SQL Editor откройте файл `supabase/migrations/002_sample_data.sql`
2. Скопируйте SQL код и выполните его
3. Это добавит примеры отзывов, проектов и портфолио для тестирования

## Шаг 6: Настройка Row Level Security (RLS)

RLS уже настроен в миграции `001_initial_schema.sql`. Политики безопасности:
- **Заявки (orders)**: Любой может создавать заявки, только авторизованные пользователи могут их читать
- **Портфолио, Отзывы, Проекты**: Все могут читать опубликованные записи, только авторизованные могут управлять

## Шаг 7: Проверка работы

1. Откройте сайт в браузере
2. Откройте консоль разработчика (F12)
3. Проверьте, что нет ошибок подключения к Supabase
4. Попробуйте отправить форму заказа
5. Проверьте, что данные появились в таблице `orders` в Supabase

## Структура базы данных

### Таблицы:

1. **orders** - Заявки от клиентов
   - id (UUID)
   - name (TEXT)
   - phone (TEXT)
   - message (TEXT)
   - privacy_accepted (BOOLEAN)
   - status (TEXT)
   - created_at, updated_at

2. **portfolio** - Работы портфолио
   - id (UUID)
   - title (TEXT)
   - image_url (TEXT)
   - video_url (TEXT)
   - category (TEXT)
   - width, height (INTEGER)
   - format (TEXT)
   - project_id (UUID, ссылка на projects)
   - is_published (BOOLEAN)
   - order_index (INTEGER)

3. **reviews** - Отзывы клиентов
   - id (UUID)
   - author_name (TEXT)
   - author_avatar_url (TEXT)
   - rating (INTEGER, 1-5)
   - text (TEXT)
   - is_published (BOOLEAN)
   - order_index (INTEGER)

4. **projects** - Проекты
   - id (UUID)
   - title (TEXT)
   - slug (TEXT, уникальный)
   - description (TEXT)
   - main_video_url (TEXT)
   - main_image_url (TEXT)
   - release_date (DATE)
   - team_members (JSONB)
   - is_published (BOOLEAN)
   - order_index (INTEGER)

5. **project_videos** - Видео проектов
   - id (UUID)
   - project_id (UUID)
   - title (TEXT)
   - video_url (TEXT)
   - thumbnail_url (TEXT)
   - category (TEXT)
   - video_type (TEXT)
   - order_index (INTEGER)

## Управление данными

### Через веб-интерфейс Supabase:
- Перейдите в **Table Editor** для просмотра и редактирования данных
- Используйте **SQL Editor** для сложных запросов

### Через API:
Все функции доступны через модуль `js/supabase-client.js`:
- `createOrder()` - создание заявки
- `getPortfolio()` - получение портфолио
- `getReviews()` - получение отзывов
- `getProjects()` - получение проектов
- `getProjectBySlug()` - получение проекта по slug

## Безопасность

- **RLS включен** для всех таблиц
- **Публичный доступ** только для чтения опубликованных данных
- **Создание заявок** доступно всем (для формы обратной связи)
- **Управление данными** требует аутентификации

Для управления данными через веб-интерфейс Supabase вам нужно быть авторизованным в панели управления.

## Troubleshooting

### Ошибка подключения к Supabase
- Проверьте правильность URL и ключа в `supabase/config.js`
- Убедитесь, что проект Supabase активен
- Проверьте консоль браузера на наличие ошибок CORS

### Данные не загружаются
- Проверьте RLS политики в Supabase
- Убедитесь, что записи имеют `is_published = true`
- Проверьте SQL Editor на наличие ошибок

### Форма не отправляется
- Проверьте консоль браузера на ошибки
- Убедитесь, что таблица `orders` создана
- Проверьте RLS политики для таблицы `orders`

## Дополнительные ресурсы

- [Документация Supabase](https://supabase.com/docs)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript/introduction)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
