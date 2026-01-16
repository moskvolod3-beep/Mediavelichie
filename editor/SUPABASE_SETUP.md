# Настройка Supabase Storage для сохранения кадров

## Вариант 1: Использование облачного Supabase (рекомендуется для начала)

### Шаги настройки:

1. **Создайте проект на Supabase:**
   - Перейдите на https://supabase.com
   - Зарегистрируйтесь и создайте новый проект
   - Дождитесь завершения создания проекта (обычно 2-3 минуты)

2. **Получите ключи доступа:**
   - В панели проекта перейдите в Settings → API
   - Скопируйте:
     - `URL` (Project URL)
     - `service_role` ключ (Service Role Key) - **НЕ используйте anon key для загрузки файлов!**

3. **Создайте бакет для хранения кадров:**
   - Перейдите в Storage в левом меню
   - Нажмите "New bucket"
   - Название: `frames` (или другое на ваше усмотрение)
   - Выберите "Public bucket" если хотите, чтобы файлы были публично доступны
   - Нажмите "Create bucket"

4. **Настройте переменные окружения:**
   Создайте файл `.env` в папке `Редактор`:
   ```env
   BUCKET_ENABLED=true
   BUCKET_TYPE=supabase
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_KEY=your-service-role-key-here
   SUPABASE_BUCKET=frames
   ```

5. **Установите зависимости:**
   ```bash
   pip install supabase
   ```

6. **Запустите приложение:**
   ```bash
   python app.py
   ```

## Вариант 2: Локальный Supabase с Docker (для разработки)

### Использование официального Supabase CLI:

1. **Установите Supabase CLI:**
   ```bash
   # Windows (через Scoop)
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   
   # Или через npm
   npm install -g supabase
   ```

2. **Инициализируйте проект:**
   ```bash
   cd Редактор
   supabase init
   ```

3. **Запустите локальный Supabase:**
   ```bash
   supabase start
   ```

4. **Получите ключи:**
   После запуска вы увидите:
   ```
   API URL: http://localhost:54321
   GraphQL URL: http://localhost:54321/graphql/v1
   S3 URL: http://localhost:54321/storage/v1/s3
   Studio URL: http://localhost:54321
   anon key: eyJ...
   service_role key: eyJ...
   ```

5. **Создайте бакет через Studio:**
   - Откройте Studio URL в браузере (обычно http://localhost:54321)
   - Перейдите в Storage
   - Создайте новый бакет `frames`

6. **Настройте переменные окружения:**
   ```env
   BUCKET_ENABLED=true
   BUCKET_TYPE=supabase
   SUPABASE_URL=http://localhost:54321
   SUPABASE_KEY=your-service-role-key-from-cli
   SUPABASE_BUCKET=frames
   ```

### Использование Docker Compose напрямую:

Если CLI не подходит, можно использовать упрощенный docker-compose:

1. **Создайте файл `docker-compose.supabase.yml`:**
   ```yaml
   version: '3.8'
   services:
     postgres:
       image: supabase/postgres:15.1.0.117
       ports:
         - "54322:5432"
       environment:
         POSTGRES_PASSWORD: your-super-secret-password
         POSTGRES_DB: postgres
       volumes:
         - supabase-db-data:/var/lib/postgresql/data
   
     studio:
       image: supabase/studio:latest
       ports:
         - "3000:3000"
       depends_on:
         - postgres
   ```

2. **Запустите:**
   ```bash
   docker-compose -f docker-compose.supabase.yml up -d
   ```

**Примечание:** Для полной функциональности Storage лучше использовать официальный CLI подход.

## Проверка работы

1. Запустите приложение
2. Перейдите на вкладку "Извлечение кадров"
3. Загрузите видео
4. Отметьте "Сохранить в бакет (bucket storage)"
5. Нажмите "Извлечь кадры"
6. Проверьте в Supabase Studio (Storage → frames), что кадры появились

## Troubleshooting

### Ошибка: "SUPABASE_URL и SUPABASE_KEY не настроены"
- Убедитесь, что переменные окружения установлены правильно
- Проверьте, что файл `.env` находится в правильной папке

### Ошибка: "supabase не установлен"
- Выполните: `pip install supabase`

### Ошибка: "Ошибка загрузки в Supabase Storage"
- Проверьте, что используется `service_role` ключ, а не `anon` ключ
- Убедитесь, что бакет создан и имеет правильное имя
- Проверьте права доступа к бакету

### Файлы не появляются в Storage
- Проверьте, что бакет существует
- Убедитесь, что используется правильный `SUPABASE_BUCKET` в конфигурации
- Проверьте логи приложения на наличие ошибок

## Дополнительные настройки

### Настройка политик доступа (RLS)

Для публичных бакетов можно настроить политики Row Level Security:

1. В Supabase Studio перейдите в Storage → Policies
2. Создайте политику для вашего бакета:
   ```sql
   -- Политика для чтения (если бакет публичный)
   CREATE POLICY "Public Access"
   ON storage.objects FOR SELECT
   USING (bucket_id = 'frames');
   
   -- Политика для записи (только для авторизованных или через service_role)
   CREATE POLICY "Authenticated users can upload"
   ON storage.objects FOR INSERT
   WITH CHECK (bucket_id = 'frames');
   ```

Однако для нашего случая (использование service_role key) политики не требуются, так как service_role ключ обходит все политики безопасности.


