# Используем официальный образ Nginx
FROM nginx:alpine

# Копируем файлы сайта в директорию Nginx
COPY . /usr/share/nginx/html

# Копируем кастомную конфигурацию Nginx (опционально)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Открываем порт 80
EXPOSE 80

# Nginx запускается автоматически при старте контейнера
