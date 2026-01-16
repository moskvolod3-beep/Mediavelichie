# Быстрый старт с локальным Supabase

## Шаг 1: Запустите Docker Desktop

Убедитесь, что Docker Desktop запущен и работает.

## Шаг 2: Запустите локальный Supabase

```powershell
.\start-supabase-local.ps1
```

Или вручную:
```powershell
supabase start
```

Первый запуск займет несколько минут (скачивание образов).

## Шаг 3: Обновите конфигурацию

```powershell
.\update-local-config.ps1
```

Это автоматически обновит `supabase/config.local.js` с данными локального Supabase.

## Шаг 4: Обновите импорт в коде (опционально)

Для использования локального конфига измените в `js/supabase-client.js`:

```javascript
// Замените эту строку:
import { SUPABASE_CONFIG, TABLES } from '../supabase/config.js';

// На эту (для локальной разработки):
import { SUPABASE_CONFIG, TABLES } from '../supabase/config.local.js';
```

Или создайте условие для автоматического переключения между локальным и продакшен конфигом.

## Шаг 5: Откройте Supabase Studio

После запуска выполните:
```powershell
supabase status
```

Откройте **Studio URL** в браузере (обычно http://localhost:54323)

## Готово!

Теперь вы можете:
- ✅ Работать с локальной базой данных
- ✅ Тестировать формы и API
- ✅ Управлять данными через Studio
- ✅ Разрабатывать без интернета

## Остановка

```powershell
supabase stop
```

## Перенос на продакшен

См. `DEPLOY_TO_PRODUCTION.md` для подробных инструкций.

## Дополнительная информация

- `LOCAL_SUPABASE.md` - подробное руководство по локальной разработке
- `DEPLOY_TO_PRODUCTION.md` - инструкции по деплою
- `SUPABASE_SETUP.md` - общая информация о Supabase
