# Dockerfile для фронтенда Mediavelichia
# Используется для сборки продакшен образа с Nginx

FROM nginx:alpine

# Build arguments для Supabase конфигурации
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
ARG FRONTEND_DIR=frontend

# Копируем файлы сайта из директории frontend
COPY ${FRONTEND_DIR} /usr/share/nginx/html

# Копируем конфигурацию Nginx
COPY ${FRONTEND_DIR}/nginx.conf /etc/nginx/conf.d/default.conf

# Заменяем плейсхолдеры в config.prod.js на реальные значения
# (если переменные переданы через build args)
RUN if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then \
    sed -i "s|SUPABASE_URL_PLACEHOLDER|${SUPABASE_URL}|g" /usr/share/nginx/html/supabase/config.prod.js && \
    sed -i "s|SUPABASE_ANON_KEY_PLACEHOLDER|${SUPABASE_ANON_KEY}|g" /usr/share/nginx/html/supabase/config.prod.js; \
    fi

# Открываем порты
EXPOSE 80 443

# Nginx запускается автоматически при старте контейнера
