# Mediavelichia

Корпоративный сайт цифрового агентства с портфолио и управлением контентом.

## Структура проекта

- **frontend/** - Статический сайт (HTML, CSS, JavaScript)
- **backend/service1/** - Flask сервер для обработки видео и управления портфолио
- **backend/supabase/** - Миграции базы данных Supabase

## Технологии

- Frontend: HTML5, CSS3, Vanilla JavaScript
- Backend: Flask (Python)
- Database: Supabase (PostgreSQL)
- Containerization: Docker, Docker Compose
- Web Server: Nginx

## Быстрый старт

### Локальная разработка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/moskvolod3-beep/Mediavelichie.git
cd Mediavelichie
```

2. Создайте файл `.env` на основе `.env.example`:
```bash
cp .env.example .env
```

3. Запустите контейнеры:
```bash
docker-compose up -d
```

4. Откройте браузер: http://localhost

### Продакшен деплой

См. документацию в `.github/workflows/` для автоматического деплоя через GitHub Actions.

Для ручного деплоя на сервер используйте `docker-compose.prod.yml` или `docker-compose.prod.cloud.yml` (для облачного Supabase).

## Конфигурация

### Переменные окружения

Скопируйте `.env.example` в `.env` и заполните:

- `SUPABASE_URL` - URL вашего проекта Supabase
- `SUPABASE_ANON_KEY` - Anon public key из Supabase
- `SUPABASE_SERVICE_KEY` - Service role key для backend операций
- `SUPABASE_BUCKET` - Имя bucket для портфолио

Подробнее см. `.env.example`

## Документация

- Настройка Supabase: см. файлы `*SUPABASE*.md` в корне проекта
- Деплой на сервер: см. файлы `*DEPLOY*.md` в корне проекта
- GitHub Actions: см. `.github/workflows/`

## Лицензия

Private project
