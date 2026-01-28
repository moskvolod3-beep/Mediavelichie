# Исправление ошибки YAML в docker-compose.prod.cloud.yml

## Проблема

При запуске `docker compose -f docker-compose.prod.cloud.yml up -d --build` возникает ошибка:
```
yaml: line 62: did not find expected comment or line break
```

## Решение

### Быстрое решение: Обновить файл из репозитория

```bash
cd /opt/mediavelichia
git pull origin main
```

### Ручное исправление

Отредактируйте файл `docker-compose.prod.cloud.yml` на строке 62:

**Было:**
```yaml
test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5000/health"] || exit 0
```

**Стало:**
```yaml
test: ["CMD-SHELL", "wget --quiet --tries=1 --spider http://localhost:5000/health || exit 0"]
```

### Автоматическое исправление через sed

```bash
cd /opt/mediavelichia
sed -i 's|test: \["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5000/health"\] || exit 0|test: ["CMD-SHELL", "wget --quiet --tries=1 --spider http://localhost:5000/health || exit 0"]|g' docker-compose.prod.cloud.yml
```

## Проверка

```bash
# Проверка синтаксиса
docker compose -f docker-compose.prod.cloud.yml config > /dev/null && echo "✓ YAML синтаксис корректен"
```

## Запуск

```bash
docker compose -f docker-compose.prod.cloud.yml up -d --build
```
