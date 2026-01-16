# Интеграция Supabase - Краткое руководство

## Быстрый старт

1. **Создайте проект на Supabase**
   - Зайдите на https://supabase.com
   - Создайте новый проект

2. **Настройте конфигурацию**
   - Откройте `supabase/config.js`
   - Замените `YOUR_SUPABASE_URL` и `YOUR_SUPABASE_ANON_KEY` на ваши значения из Supabase Dashboard

3. **Создайте таблицы**
   - В Supabase Dashboard откройте SQL Editor
   - Выполните SQL из `supabase/migrations/001_initial_schema.sql`
   - (Опционально) Выполните `supabase/migrations/002_sample_data.sql` для тестовых данных

4. **Готово!**
   - Формы заказа теперь сохраняются в базу данных
   - Портфолио и отзывы загружаются из Supabase
   - Если Supabase недоступен, используется fallback данные

## Структура файлов

```
supabase/
├── config.js              # Конфигурация Supabase (URL и ключи)
├── migrations/
│   ├── 001_initial_schema.sql  # Создание таблиц
│   └── 002_sample_data.sql     # Тестовые данные
└── SUPABASE_SETUP.md      # Подробное руководство

js/
├── supabase-client.js      # Клиент для работы с Supabase API
├── order-popup.js          # Интеграция формы заказа
├── portfolio.js            # Загрузка портфолио из БД
└── reviews-loader.js       # Загрузка отзывов из БД
```

## Основные функции

### Заявки (Orders)
- `createOrder(data)` - создание новой заявки
- Автоматически вызывается при отправке форм на сайте

### Портфолио (Portfolio)
- `getPortfolio(category)` - получение работ портфолио
- Автоматически загружается на странице portfolio.html

### Отзывы (Reviews)
- `getReviews()` - получение всех опубликованных отзывов
- Автоматически загружаются на главной странице

### Проекты (Projects)
- `getProjects()` - получение всех проектов
- `getProjectBySlug(slug)` - получение проекта по slug

## Безопасность

- Row Level Security (RLS) включен для всех таблиц
- Публичный доступ только для чтения опубликованных данных
- Создание заявок доступно всем (для форм обратной связи)
- Управление данными требует аутентификации в Supabase Dashboard

## Fallback режим

Если Supabase не настроен или недоступен:
- Формы будут показывать успешное сообщение (graceful degradation)
- Портфолио использует fallback данные из `portfolio.js`
- Отзывы не загружаются (используются статические из HTML)

## Подробная документация

См. `SUPABASE_SETUP.md` для полного руководства по настройке.
