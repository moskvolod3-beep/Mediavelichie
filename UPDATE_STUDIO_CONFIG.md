# Обновление конфигурации Supabase Studio

## Что изменено

1. **Добавлен сервис `supabase-meta`** - предоставляет API для работы со схемой БД
2. **Обновлена конфигурация Studio** - теперь использует `STUDIO_PG_META_URL` для автоматического подключения
3. **Обновлен `.env.example`** - добавлены переменные для Studio

## Как применить изменения

### На сервере:

```bash
cd /opt/mediavelichia

# 1. Обновите код
git pull origin main

# 2. Убедитесь что .env файл содержит правильные значения
cat .env | grep POSTGRES_PASSWORD

# 3. Перезапустите контейнеры с новой конфигурацией
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# 4. Проверьте что все сервисы запущены
docker ps | grep mediavelichie

# 5. Проверьте логи Studio
docker logs mediavelichie-supabase-studio --tail 50

# 6. Проверьте логи pg-meta
docker logs mediavelichie-supabase-meta --tail 50
```

## Что должно работать теперь

После перезапуска Studio должен **автоматически подключиться** к PostgreSQL через pg-meta сервис:

1. ✅ Studio получает метаданные БД через `http://supabase-meta:8080`
2. ✅ Не нужно вручную вводить данные подключения
3. ✅ Полный функционал Studio доступен (таблицы, SQL редактор, схема)

## Проверка работы

1. Откройте Studio: http://194.58.88.127:3000
2. Вы должны увидеть интерфейс Studio с подключенной БД (без формы подключения)
3. В разделе "Table Editor" должны быть видны таблицы

## Если что-то не работает

### Проверьте что pg-meta запущен:
```bash
docker ps | grep supabase-meta
docker logs mediavelichie-supabase-meta
```

### Проверьте подключение pg-meta к БД:
```bash
# Из контейнера pg-meta
docker exec mediavelichie-supabase-meta wget -qO- http://localhost:8080/health
```

### Проверьте переменные окружения Studio:
```bash
docker exec mediavelichie-supabase-studio env | grep STUDIO
```

Должно быть:
```
STUDIO_PG_META_URL=http://supabase-meta:8080
```

## Откат изменений

Если что-то пошло не так, можно вернуться к предыдущей конфигурации:

```bash
git checkout HEAD~1 docker-compose.prod.yml .env.example
docker compose -f docker-compose.prod.yml up -d
```

Но тогда Studio снова потребует ручного подключения через веб-интерфейс.
