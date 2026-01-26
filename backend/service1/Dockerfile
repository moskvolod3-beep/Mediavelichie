FROM python:3.11-slim

# Установка FFmpeg
RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копирование requirements
COPY requirements.txt .

# Установка зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копирование кода приложения
COPY . .

# Создание директории для временных файлов
RUN mkdir -p /app/temp

# Открываем порт
EXPOSE 5000

# Запуск приложения
CMD ["python", "app.py"]
