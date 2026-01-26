# Инструкция по развертыванию на сервере

## Структура контейнеров

Проект состоит из следующих контейнеров:

1. **web** - Nginx для статического фронтенда (порт 80)
2. **backend** - Flask приложение для обработки видео (порт 5000)
3. **supabase** - PostgreSQL база данных (порт 5432)
4. **supabase-studio** - Веб-интерфейс для администрирования БД (порт 3000, опционально)

## Настройка переменных окружения

Создайте файл `.env` в директории `backend/` со следующим содержимым:

```bash
# Supabase конфигурация
# Для продакшена используйте URL вашего облачного Supabase проекта
SUPABASE_URL=https://your-project.supabase.co

# Service Role Key из настроек Supabase проекта
SUPABASE_KEY=your-service-role-key-here

# Имя бакета в Supabase Storage
SUPABASE_BUCKET=portfolio

# Пароль для PostgreSQL (если используете локальный Supabase)
POSTGRES_PASSWORD=your-super-secret-postgres-password

# JWT Secret (если используете локальный Supabase)
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
```

## Запуск проекта

### Для разработки:
```bash
cd backend
docker-compose up -d
```

### Для продакшена:
```bash
cd backend
docker-compose -f docker-compose.prod.yml --env-file .env up -d
```

## Проверка работы

- Фронтенд: http://your-server-ip
- Backend API: http://your-server-ip:5000
- Supabase Studio: http://your-server-ip:3000 (если включен)

## Порты

- **80** - Веб-сайт (Nginx)
- **443** - HTTPS (если настроен SSL)
- **5000** - Flask Backend API
- **5432** - PostgreSQL (только для внутренней сети)
- **3000** - Supabase Studio (опционально)

## Важные замечания

1. **Supabase**: Рекомендуется использовать облачный Supabase для продакшена, а не локальный контейнер
2. **Безопасность**: Не открывайте порт 5432 (PostgreSQL) наружу
3. **SSL**: Настройте SSL сертификат (Let's Encrypt) для продакшена
4. **Ресурсы**: Убедитесь, что на сервере достаточно RAM (рекомендуется 16GB) для обработки видео
