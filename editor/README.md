# Редактор разрешения видео

Веб-приложение для сжатия разрешения видео до 1080p, 720p, 480p или 360p.

## Установка

### 1. Установите FFmpeg

#### Windows:
1. Скачайте FFmpeg с https://ffmpeg.org/download.html
2. Распакуйте архив
3. Переименуйте папку в `FFmpeg` и переместите в `C:\`
4. Добавьте `C:\FFmpeg\bin` в PATH:
   - Откройте "Переменные среды"
   - Добавьте `C:\FFmpeg\bin` в переменную PATH
5. Перезагрузите компьютер

#### Linux:
```bash
sudo apt-get update
sudo apt-get install ffmpeg
```

#### macOS:
```bash
brew install ffmpeg
```

### 2. Установите зависимости Python

```bash
pip install -r requirements.txt
```

Или установите вручную:
```bash
pip install Flask Werkzeug
```

## Запуск

### Windows (рекомендуется):
Дважды кликните на файл `start.bat` или выполните в командной строке:
```bash
start.bat
```

### Linux/macOS или вручную:
```bash
pip install -r requirements.txt
python app.py
```

Приложение будет доступно по адресу: http://localhost:5000

## Использование

### Сжатие видео:

1. Откройте http://localhost:5000 в браузере
2. Перейдите на вкладку "Сжатие видео"
3. Перетащите видеофайл в область загрузки или выберите файл
4. Выберите желаемое разрешение (1080p, 720p, 480p, 360p)
5. Нажмите "Сжать видео"
6. Дождитесь обработки
7. Сжатое видео автоматически скачается

### Извлечение кадров:

1. Перейдите на вкладку "Извлечение кадров"
2. Перетащите видеофайл в область загрузки или выберите файл
3. Укажите интервал в секундах (по умолчанию 15 секунд)
4. (Опционально) Включите сохранение в бакет, если настроен
5. Нажмите "Извлечь кадры"
6. Дождитесь обработки
7. Просмотрите извлеченные кадры и скачайте их

## Поддерживаемые форматы

- MP4
- MOV
- AVI
- MKV
- WebM
- FLV
- WMV

## Технологии

- **Backend**: Flask (Python)
- **Video Processing**: FFmpeg
- **Frontend**: HTML5, CSS3, JavaScript

## Настройка бакета (Bucket Storage)

Для сохранения кадров в облачное хранилище:

1. Установите переменные окружения или создайте файл `.env`:
   ```
   BUCKET_ENABLED=true
   BUCKET_TYPE=s3  # или 'yandex'
   BUCKET_NAME=your-bucket-name
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_REGION=us-east-1  # для AWS S3
   ```

2. Или установите переменные окружения в системе

3. Пример файла конфигурации: `config.env.example`

Поддерживаемые типы бакетов:
- `local` - локальное хранение (по умолчанию)
- `s3` - Amazon S3
- `yandex` - Yandex Object Storage
- `supabase` - Supabase Storage (рекомендуется)

**Для использования Supabase Storage см. [SUPABASE_SETUP.md](SUPABASE_SETUP.md)**

## Примечания

- Максимальный размер загружаемого файла: 500MB
- Обработка происходит на сервере
- Временные файлы автоматически удаляются после обработки
- Для больших файлов обработка может занять несколько минут
- Извлеченные кадры сохраняются в формате JPEG высокого качества

## Основано на

[FFmpeg-Video-Compressor](https://github.com/MoeeinAali/FFmpeg-Video-Compressor) - Python скрипт для сжатия видео
