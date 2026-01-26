from flask import Flask, render_template, request, send_file, jsonify
import os
import subprocess
import tempfile
import uuid
import glob
import shutil
from werkzeug.utils import secure_filename
from datetime import datetime
import json

# Загружаем переменные окружения из .env файла
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # Если python-dotenv не установлен, просто пропускаем
    pass

app = Flask(__name__)

# Настройка CORS для разрешения запросов с любого источника
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response
app.config['MAX_CONTENT_LENGTH'] = 2 * 1024 * 1024 * 1024  # 2GB максимум
# Используем диск D для временных файлов, если доступен (Windows), иначе системную временную папку
# В Docker контейнере используем /app/temp
def setup_upload_folder():
    """Настраивает папку для загрузки файлов с обработкой ошибок"""
    # Проверяем /app/temp в Docker контейнере
    if os.path.exists('/app/temp'):
        if os.path.isdir('/app/temp'):
            # Это директория, используем её
            app.config['UPLOAD_FOLDER'] = '/app/temp'
            return
        else:
            # Это файл, пытаемся удалить и создать директорию
            print("[WARNING] /app/temp существует как файл, пытаемся исправить...")
            try:
                os.remove('/app/temp')
                os.makedirs('/app/temp', exist_ok=True)
                app.config['UPLOAD_FOLDER'] = '/app/temp'
                print("[OK] /app/temp успешно создан как директория")
                return
            except Exception as e:
                print(f"[ERROR] Не удалось исправить /app/temp: {e}")
                # Продолжаем с альтернативным путем
    
    # Пытаемся создать /app/temp если его нет
    try:
        os.makedirs('/app/temp', exist_ok=True)
        if os.path.isdir('/app/temp'):
            app.config['UPLOAD_FOLDER'] = '/app/temp'
            print("[OK] /app/temp создан")
            return
    except Exception as e:
        print(f"[WARNING] Не удалось создать /app/temp: {e}")
    
    # Альтернативные варианты
    if os.path.exists('D:\\'):
        alt_path = os.path.join('D:\\', 'Mediavelichia', 'editor', 'temp')
        try:
            os.makedirs(alt_path, exist_ok=True)
            app.config['UPLOAD_FOLDER'] = alt_path
            print(f"[OK] Используем альтернативный путь: {alt_path}")
            return
        except Exception as e:
            print(f"[WARNING] Не удалось создать {alt_path}: {e}")
    
    # Используем системную временную папку
    sys_temp = tempfile.gettempdir()
    try:
        os.makedirs(sys_temp, exist_ok=True)
        app.config['UPLOAD_FOLDER'] = sys_temp
        print(f"[OK] Используем системную временную папку: {sys_temp}")
    except Exception as e:
        print(f"[ERROR] Критическая ошибка: не удалось настроить папку для загрузки: {e}")
        raise

setup_upload_folder()
app.config['SECRET_KEY'] = os.urandom(24)

# Настройки бакета (можно вынести в переменные окружения или конфиг файл)
app.config['BUCKET_ENABLED'] = os.environ.get('BUCKET_ENABLED', 'false').lower() == 'true'
app.config['BUCKET_TYPE'] = os.environ.get('BUCKET_TYPE', 'local')  # 's3', 'yandex', 'supabase', 'local'
app.config['BUCKET_NAME'] = os.environ.get('BUCKET_NAME', '')
app.config['AWS_ACCESS_KEY_ID'] = os.environ.get('AWS_ACCESS_KEY_ID', '')
app.config['AWS_SECRET_ACCESS_KEY'] = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
app.config['AWS_REGION'] = os.environ.get('AWS_REGION', 'us-east-1')
app.config['YANDEX_ENDPOINT'] = os.environ.get('YANDEX_ENDPOINT', 'https://storage.yandexcloud.net')

# Настройки Supabase
app.config['SUPABASE_URL'] = os.environ.get('SUPABASE_URL', '')
app.config['SUPABASE_KEY'] = os.environ.get('SUPABASE_KEY', '')  # Service Role Key для полного доступа
app.config['SUPABASE_BUCKET'] = os.environ.get('SUPABASE_BUCKET', 'frames')  # Имя бакета в Supabase Storage

ALLOWED_EXTENSIONS = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def extract_frames(input_path, output_dir, interval_seconds=15):
    """Извлекает кадры из видео каждые N секунд"""
    try:
        # Создаем папку для кадров
        os.makedirs(output_dir, exist_ok=True)
        
        # Команда FFmpeg для извлечения кадров
        # -ss пропускает первые N секунд, -i входной файл
        # -vf fps=1/15 означает 1 кадр каждые 15 секунд
        # %04d - нумерация кадров с 4 цифрами
        output_pattern = os.path.join(output_dir, 'frame_%04d.jpg')
        
        cmd = [
            'ffmpeg',
            '-i', input_path,
            '-vf', f'fps=1/{interval_seconds}',  # 1 кадр каждые N секунд
            '-q:v', '2',  # Качество JPEG (1-31, 2 = высокое качество)
            '-y',  # Перезаписать существующие файлы
            output_pattern
        ]
        
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
            timeout=3600  # 60 минут максимум для больших файлов
        )
        
        # Получаем список извлеченных кадров
        frames = sorted(glob.glob(os.path.join(output_dir, 'frame_*.jpg')))
        return True, frames, None
        
    except subprocess.TimeoutExpired:
        return False, [], "Превышено время ожидания обработки"
    except subprocess.CalledProcessError as e:
        error_msg = e.stderr.decode('utf-8', errors='ignore')
        return False, [], f"Ошибка FFmpeg: {error_msg}"
    except Exception as e:
        return False, [], f"Ошибка извлечения кадров: {str(e)}"

def upload_to_bucket(file_path, bucket_path, bucket_type='local'):
    """Загружает файл в бакет (bucket storage)"""
    if bucket_type == 'local':
        # Для локального хранения просто возвращаем путь
        return file_path, None
    
    elif bucket_type == 's3':
        try:
            import boto3
            s3_client = boto3.client(
                's3',
                aws_access_key_id=app.config['AWS_ACCESS_KEY_ID'],
                aws_secret_access_key=app.config['AWS_SECRET_ACCESS_KEY'],
                region_name=app.config['AWS_REGION']
            )
            
            bucket_name = app.config['BUCKET_NAME']
            s3_client.upload_file(file_path, bucket_name, bucket_path)
            
            # Формируем URL
            url = f"https://{bucket_name}.s3.{app.config['AWS_REGION']}.amazonaws.com/{bucket_path}"
            return url, None
            
        except ImportError:
            return None, "boto3 не установлен. Установите: pip install boto3"
        except Exception as e:
            return None, f"Ошибка загрузки в S3: {str(e)}"
    
    elif bucket_type == 'yandex':
        try:
            import boto3
            s3_client = boto3.client(
                's3',
                endpoint_url=app.config['YANDEX_ENDPOINT'],
                aws_access_key_id=app.config['AWS_ACCESS_KEY_ID'],
                aws_secret_access_key=app.config['AWS_SECRET_ACCESS_KEY']
            )
            
            bucket_name = app.config['BUCKET_NAME']
            s3_client.upload_file(file_path, bucket_name, bucket_path)
            
            url = f"{app.config['YANDEX_ENDPOINT']}/{bucket_name}/{bucket_path}"
            return url, None
            
        except ImportError:
            return None, "boto3 не установлен. Установите: pip install boto3"
        except Exception as e:
            return None, f"Ошибка загрузки в Yandex Object Storage: {str(e)}"
    
    elif bucket_type == 'supabase':
        try:
            from supabase import create_client, Client
            
            supabase_url = app.config['SUPABASE_URL']
            supabase_key = app.config['SUPABASE_KEY']
            bucket_name = app.config['SUPABASE_BUCKET']
            
            if not supabase_url or not supabase_key:
                return None, "SUPABASE_URL и SUPABASE_KEY не настроены"
            
            # Создаем клиент Supabase
            supabase: Client = create_client(supabase_url, supabase_key)
            
            # Читаем файл
            with open(file_path, 'rb') as f:
                file_data = f.read()
            
            # Загружаем файл в Supabase Storage
            storage_client = supabase.storage.from_(bucket_name)
            
            # Пытаемся загрузить файл (с автоматической перезаписью если существует)
            try:
                # Используем upload с опцией upsert для перезаписи существующих файлов
                response = storage_client.upload(
                    path=bucket_path,
                    file=file_data,
                    file_options={
                        "content-type": "image/jpeg",
                        "upsert": "true"
                    }
                )
            except Exception as upload_error:
                # Если upload не сработал, пробуем обновить существующий файл
                error_str = str(upload_error)
                if "already exists" in error_str.lower() or "duplicate" in error_str.lower():
                    try:
                        response = storage_client.update(
                            path=bucket_path,
                            file=file_data,
                            file_options={"content-type": "image/jpeg"}
                        )
                    except Exception as update_error:
                        return None, f"Ошибка обновления файла: {str(update_error)}"
                else:
                    return None, f"Ошибка загрузки файла: {error_str}"
            
            # Получаем публичный URL
            # get_public_url возвращает строку с URL
            try:
                url = storage_client.get_public_url(bucket_path)
                # Если это словарь, извлекаем URL
                if isinstance(url, dict):
                    url = url.get('publicUrl', '')
            except Exception:
                # Если метод не работает, формируем URL вручную
                url = f"{supabase_url}/storage/v1/object/public/{bucket_name}/{bucket_path}"
            
            # Убеждаемся, что у нас есть валидный URL
            if not url:
                url = f"{supabase_url}/storage/v1/object/public/{bucket_name}/{bucket_path}"
            
            return url, None
            
        except ImportError:
            return None, "supabase не установлен. Установите: pip install supabase"
        except Exception as e:
            error_msg = str(e)
            return None, f"Ошибка загрузки в Supabase Storage: {error_msg}"
    
    return None, f"Неподдерживаемый тип бакета: {bucket_type}"

def compress_video(input_path, output_path, resolution):
    """Сжимает видео до указанного разрешения используя FFmpeg"""
    resolutions = {
        '1080': {'width': 1920, 'height': 1080},
        '720': {'width': 1280, 'height': 720},
        '480': {'width': 854, 'height': 480},
        '360': {'width': 640, 'height': 360}
    }
    
    if resolution not in resolutions:
        raise ValueError(f"Неподдерживаемое разрешение: {resolution}")
    
    # Команда FFmpeg для сжатия видео
    # Используем scale с сохранением пропорций и округлением до четных чисел
    target_res = resolutions[resolution]
    # Используем -2 для автоматического округления до ближайшего четного числа
    # force_original_aspect_ratio=decrease - сохраняет пропорции, не добавляет черные полосы
    # Это гарантирует, что размеры будут четными (требование libx264)
    scale_filter = f"scale={target_res['width']}:-2:force_original_aspect_ratio=decrease"
    
    cmd = [
        'ffmpeg',
        '-i', input_path,
        '-vf', scale_filter,
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', '23',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-movflags', '+faststart',
        '-y',  # Перезаписать выходной файл
        output_path
    ]
    
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
            timeout=3600  # 60 минут максимум для больших файлов
        )
        return True, None
    except subprocess.TimeoutExpired:
        return False, "Превышено время ожидания обработки"
    except subprocess.CalledProcessError as e:
        return False, f"Ошибка FFmpeg: {e.stderr.decode('utf-8', errors='ignore')}"
    except FileNotFoundError:
        return False, "FFmpeg не найден. Убедитесь, что FFmpeg установлен и доступен в PATH"

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'Файл не загружен'}), 400
    
    file = request.files['file']
    resolution = request.form.get('resolution', '720')
    
    if file.filename == '':
        return jsonify({'error': 'Файл не выбран'}), 400
    
    if not allowed_file(file.filename):
        return jsonify({'error': 'Неподдерживаемый формат файла'}), 400
    
    if resolution not in ['1080', '720', '480', '360']:
        return jsonify({'error': 'Неподдерживаемое разрешение'}), 400
    
    try:
        # Сохраняем загруженный файл
        file_id = str(uuid.uuid4())
        input_filename = secure_filename(file.filename)
        # Проверяем наличие расширения
        if '.' in input_filename:
            input_ext = input_filename.rsplit('.', 1)[1].lower()
        else:
            # Если расширения нет, пытаемся определить по MIME типу или используем mp4 по умолчанию
            input_ext = 'mp4'
        input_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{file_id}_input.{input_ext}')
        output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{file_id}_output.mp4')
        
        file.save(input_path)
        
        # Сжимаем видео
        success, error = compress_video(input_path, output_path, resolution)
        
        if not success:
            # Удаляем входной файл
            if os.path.exists(input_path):
                os.remove(input_path)
            return jsonify({'error': error}), 500
        
        # Возвращаем сжатое видео
        response = send_file(
            output_path,
            mimetype='video/mp4',
            as_attachment=True,
            download_name=f'compressed_{resolution}p_{input_filename}'
        )
        
        # Удаляем временные файлы после отправки (в фоновом режиме)
        def remove_files():
            import time
            time.sleep(5)  # Даем время на скачивание
            if os.path.exists(input_path):
                os.remove(input_path)
            if os.path.exists(output_path):
                os.remove(output_path)
        
        # Запускаем удаление в фоне (упрощенный вариант)
        import threading
        threading.Thread(target=remove_files, daemon=True).start()
        
        return response
        
    except Exception as e:
        return jsonify({'error': f'Ошибка обработки: {str(e)}'}), 500

@app.route('/extract-frames', methods=['POST'])
def extract_frames_endpoint():
    """Извлекает кадры из видео каждые 15 секунд и сохраняет в бакет"""
    if 'file' not in request.files:
        return jsonify({'error': 'Файл не загружен'}), 400
    
    file = request.files['file']
    interval = int(request.form.get('interval', 15))  # Интервал в секундах
    bucket_enabled = request.form.get('bucket_enabled', 'false').lower() == 'true'
    
    if file.filename == '':
        return jsonify({'error': 'Файл не выбран'}), 400
    
    if not allowed_file(file.filename):
        return jsonify({'error': 'Неподдерживаемый формат файла'}), 400
    
    try:
        # Сохраняем загруженный файл
        file_id = str(uuid.uuid4())
        input_filename = secure_filename(file.filename)
        # Проверяем наличие расширения
        if '.' in input_filename:
            input_ext = input_filename.rsplit('.', 1)[1].lower()
        else:
            # Если расширения нет, пытаемся определить по MIME типу или используем mp4 по умолчанию
            input_ext = 'mp4'
        input_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{file_id}_input.{input_ext}')
        frames_dir = os.path.join(app.config['UPLOAD_FOLDER'], f'{file_id}_frames')
        
        file.save(input_path)
        
        # Извлекаем кадры
        success, frames, error = extract_frames(input_path, frames_dir, interval)
        
        if not success:
            if os.path.exists(input_path):
                os.remove(input_path)
            return jsonify({'error': error}), 500
        
        uploaded_files = []
        errors = []
        bucket_type = app.config['BUCKET_TYPE'] if bucket_enabled and app.config['BUCKET_ENABLED'] else 'local'
        
        # Создаем статическую папку для кадров, если нужно
        static_frames_base = os.path.join(os.path.dirname(__file__), 'static', 'frames')
        static_frames_dir = os.path.join(static_frames_base, file_id)
        if bucket_type == 'local':
            os.makedirs(static_frames_dir, exist_ok=True)
        
        # Загружаем каждый кадр в бакет или копируем в статическую папку
        for idx, frame_path in enumerate(frames):
            frame_filename = os.path.basename(frame_path)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            
            if bucket_enabled and app.config['BUCKET_ENABLED']:
                # Формируем путь в бакете
                bucket_path = f"frames/{file_id}/{timestamp}_{frame_filename}"
                url, upload_error = upload_to_bucket(frame_path, bucket_path, bucket_type)
                
                if url:
                    uploaded_files.append({
                        'filename': frame_filename,
                        'url': url,
                        'local_path': frame_path,
                        'index': idx + 1
                    })
                else:
                    errors.append(f"Ошибка загрузки {frame_filename}: {upload_error}")
            else:
                # Локальное хранение - копируем в статическую папку
                try:
                    static_frame_path = os.path.join(static_frames_dir, frame_filename)
                    shutil.copy2(frame_path, static_frame_path)
                    
                    uploaded_files.append({
                        'filename': frame_filename,
                        'url': f'/static/frames/{file_id}/{frame_filename}',
                        'local_path': static_frame_path,
                        'index': idx + 1
                    })
                except Exception as e:
                    errors.append(f"Ошибка копирования {frame_filename}: {str(e)}")
        
        # Формируем ответ
        result = {
            'success': True,
            'frames_count': len(uploaded_files),
            'frames': uploaded_files,
            'bucket_type': bucket_type,
            'bucket_enabled': bucket_enabled and app.config['BUCKET_ENABLED']
        }
        
        if errors:
            result['errors'] = errors
        
        # Удаляем входной файл в фоне
        def cleanup():
            import time
            time.sleep(10)  # Даем время на обработку
            if os.path.exists(input_path):
                os.remove(input_path)
            # Кадры оставляем для возможности скачивания
        
        import threading
        threading.Thread(target=cleanup, daemon=True).start()
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': f'Ошибка обработки: {str(e)}'}), 500

@app.route('/static/frames/<file_id>/<filename>')
def serve_frame(file_id, filename):
    """Отдает кадр из статической папки"""
    try:
        frame_path = os.path.join(os.path.dirname(__file__), 'static', 'frames', file_id, filename)
        if os.path.exists(frame_path):
            return send_file(frame_path, mimetype='image/jpeg')
        else:
            return jsonify({'error': 'Файл не найден'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    # Проверяем наличие FFmpeg
    try:
        result = subprocess.run(['ffmpeg', '-version'], 
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.PIPE, 
                              timeout=5)
        if result.returncode == 0:
            return jsonify({'status': 'ok', 'ffmpeg': 'installed'})
        else:
            return jsonify({'status': 'ok', 'ffmpeg': 'not_found'})
    except FileNotFoundError:
        return jsonify({'status': 'ok', 'ffmpeg': 'not_found'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

# ============================================
# АДМИН-ПАНЕЛЬ: Загрузка видео в портфолио
# ============================================

# Маппинг категорий для папок в Storage
CATEGORY_FOLDER_MAP = {
    'ekspertnye': 'Expertniye',
    'hr': 'HR-video',
    'ohvatnye': 'Ohvatnye',
    'reklamnye': 'Reklamniye',
    'sfery': 'Sfery'
}

def upload_to_supabase_storage(file_path, storage_path, bucket_name='portfolio'):
    """Загружает файл в Supabase Storage используя прямой HTTP API"""
    try:
        import httpx
        
        supabase_url = app.config.get('SUPABASE_URL', '').rstrip('/')
        supabase_key = app.config.get('SUPABASE_KEY', '')
        
        if not supabase_url or not supabase_key:
            return None, 'Supabase URL или KEY не установлены'
        
        # Формируем URL для загрузки
        upload_url = f"{supabase_url}/storage/v1/object/{bucket_name}/{storage_path}"
        
        # Читаем файл
        with open(file_path, 'rb') as f:
            file_data = f.read()
        
        # Загружаем файл
        headers = {
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/octet-stream',
            'x-upsert': 'true'  # Перезаписываем если существует
        }
        
        # Настройки для обхода прокси при работе с localhost
        # Используем trust_env=False для отключения прокси из переменных окружения
        client_kwargs = {'timeout': 300.0}
        if '127.0.0.1' in supabase_url or 'localhost' in supabase_url:
            # Отключаем использование переменных окружения для прокси (обход Privoxy)
            client_kwargs['trust_env'] = False
        
        with httpx.Client(**client_kwargs) as client:
            response = client.post(upload_url, content=file_data, headers=headers)
            
            if response.status_code in [200, 201]:
                # Формируем публичный URL в формате полного пути для сохранения в БД
                # Формат: /storage/v1/object/public/portfolio/{folder}/{filename}
                public_url = f"/storage/v1/object/public/{bucket_name}/{storage_path}"
                return public_url, None
            else:
                error_text = response.text[:500]
                return None, f'Ошибка загрузки: {response.status_code} - {error_text}'
                
    except Exception as e:
        app.logger.error(f"Ошибка загрузки в Supabase Storage: {e}")
        import traceback
        app.logger.exception("Traceback:")
        return None, str(e)

def get_supabase_client():
    """Получает клиент Supabase (для совместимости, но используем прямой API)"""
    # Проверяем наличие настроек Supabase
    supabase_url = app.config.get('SUPABASE_URL', '').rstrip('/')
    supabase_key = app.config.get('SUPABASE_KEY', '')
    
    if not supabase_url or not supabase_key:
        app.logger.warning(f"Supabase не настроен: URL={bool(supabase_url)}, KEY={bool(supabase_key)}")
        return None
    
    # Возвращаем объект-заглушку для совместимости
    class SupabaseClientStub:
        def __init__(self):
            self.storage = self
            
        def from_(self, bucket_name):
            return StorageBucketStub(bucket_name)
    
    class StorageBucketStub:
        def __init__(self, bucket_name):
            self.bucket_name = bucket_name
            
        def upload(self, path, file, file_options=None):
            # Используем прямую загрузку
            import tempfile
            with tempfile.NamedTemporaryFile(delete=False) as tmp:
                tmp.write(file if isinstance(file, bytes) else file.read())
                tmp_path = tmp.name
            
            public_url, error = upload_to_supabase_storage(tmp_path, path, self.bucket_name)
            os.unlink(tmp_path)
            
            if error:
                raise Exception(error)
            
            class Response:
                def __init__(self, url):
                    self.data = {'path': path, 'url': url}
                    self.error = None
            
            return Response(public_url)
        
        def get_public_url(self, path):
            supabase_url = app.config.get('SUPABASE_URL', '').rstrip('/')
            return f"{supabase_url}/storage/v1/object/public/{self.bucket_name}/{path}"
    
    class TableStub:
        def __init__(self, table_name):
            self.table_name = table_name
            
        def insert(self, data):
            return InsertStub(self.table_name, data)
        
        def select(self, *args):
            return SelectStub(self.table_name, args)
        
        def eq(self, column, value):
            return self
        
        def order(self, column, desc=False):
            return self
        
        def limit(self, n):
            return self
        
        def execute(self):
            return ExecuteResultStub([])
    
    class InsertStub:
        def __init__(self, table_name, data):
            self.table_name = table_name
            self.data = data
        
        def execute(self):
            return execute_supabase_insert(self.table_name, self.data)
    
    class SelectStub:
        def __init__(self, table_name, columns):
            self.table_name = table_name
            self.columns = columns
        
        def eq(self, column, value):
            self.filter_column = column
            self.filter_value = value
            return self
        
        def order(self, column, desc=False):
            self.order_column = column
            self.order_desc = desc
            return self
        
        def limit(self, n):
            self.limit_n = n
            return self
        
        def execute(self):
            return execute_supabase_select(self.table_name, getattr(self, 'filter_column', None), 
                                         getattr(self, 'filter_value', None),
                                         getattr(self, 'order_column', None),
                                         getattr(self, 'order_desc', False),
                                         getattr(self, 'limit_n', None))
    
    class ExecuteResultStub:
        def __init__(self, data):
            self.data = data
            self.error = None
    
    client_stub = SupabaseClientStub()
    client_stub.table = lambda name: TableStub(name)
    return client_stub

def execute_supabase_insert(table_name, data):
    """Выполняет INSERT запрос к Supabase через REST API"""
    try:
        import httpx
        
        supabase_url = app.config.get('SUPABASE_URL', '').rstrip('/')
        supabase_key = app.config.get('SUPABASE_KEY', '')
        
        if not supabase_url or not supabase_key:
            raise Exception('Supabase не настроен')
        
        url = f"{supabase_url}/rest/v1/{table_name}"
        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
        
        # Настройки для обхода прокси при работе с localhost
        client_kwargs = {'timeout': 30.0}
        if '127.0.0.1' in supabase_url or 'localhost' in supabase_url:
            # Отключаем использование переменных окружения для прокси
            client_kwargs['trust_env'] = False
        
        with httpx.Client(**client_kwargs) as client:
            response = client.post(url, json=data, headers=headers)
            if response.status_code in [200, 201]:
                result_data = response.json()
                class Result:
                    def __init__(self, data):
                        self.data = data if isinstance(data, list) else [data]
                        self.error = None
                return Result(result_data)
            else:
                raise Exception(f'Ошибка вставки: {response.status_code} - {response.text}')
    except Exception as e:
        app.logger.error(f"Ошибка выполнения INSERT: {e}")
        raise

def execute_supabase_select(table_name, filter_column=None, filter_value=None, 
                           order_column=None, order_desc=False, limit_n=None):
    """Выполняет SELECT запрос к Supabase через REST API"""
    try:
        import httpx
        
        supabase_url = app.config.get('SUPABASE_URL', '').rstrip('/')
        supabase_key = app.config.get('SUPABASE_KEY', '')
        
        if not supabase_url or not supabase_key:
            raise Exception('Supabase не настроен')
        
        url = f"{supabase_url}/rest/v1/{table_name}"
        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }
        
        params = {}
        if filter_column and filter_value:
            params[f'{filter_column}'] = f'eq.{filter_value}'
        if order_column:
            params['order'] = f'{order_column}.{"desc" if order_desc else "asc"}'
        if limit_n:
            params['limit'] = str(limit_n)
        
        # Настройки для обхода прокси при работе с localhost
        client_kwargs = {'timeout': 30.0}
        if '127.0.0.1' in supabase_url or 'localhost' in supabase_url:
            # Отключаем использование переменных окружения для прокси
            client_kwargs['trust_env'] = False
        
        with httpx.Client(**client_kwargs) as client:
            response = client.get(url, params=params, headers=headers)
            if response.status_code == 200:
                class Result:
                    def __init__(self, data):
                        self.data = data
                        self.error = None
                return Result(response.json())
            else:
                raise Exception(f'Ошибка выборки: {response.status_code} - {response.text}')
    except Exception as e:
        app.logger.error(f"Ошибка выполнения SELECT: {e}")
        class Result:
            def __init__(self):
                self.data = []
                self.error = str(e)
        return Result()

@app.route('/admin/test', methods=['GET'])
def admin_test():
    """Тестовый эндпоинт для проверки работы админ-панели"""
    supabase_url = app.config.get('SUPABASE_URL', '')
    supabase_key = app.config.get('SUPABASE_KEY', '')
    has_url = bool(supabase_url)
    has_key = bool(supabase_key)
    key_preview = supabase_key[:30] + '...' if supabase_key and len(supabase_key) > 30 else ('установлен' if supabase_key else 'не установлен')
    
    return jsonify({
        'success': True, 
        'message': 'Админ-панель работает!',
        'supabase_configured': has_url and has_key,
        'supabase_url': supabase_url,
        'supabase_key_preview': key_preview,
        'supabase_bucket': app.config.get('SUPABASE_BUCKET', 'не установлен')
    })

@app.route('/admin/process-video', methods=['POST'])
def admin_process_video():
    """Обрабатывает видео: сжимает до 720p и извлекает кадры"""
    try:
        print(f"[DEBUG] Запрос получен. Content-Type: {request.content_type}")
        print(f"[DEBUG] Файлы в запросе: {list(request.files.keys())}")
        
        if 'file' not in request.files:
            print("[ERROR] Файл не найден в запросе")
            return jsonify({'success': False, 'error': 'Файл не загружен'}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            print("[ERROR] Имя файла пустое")
            return jsonify({'success': False, 'error': 'Файл не выбран'}), 400
        
        if not allowed_file(file.filename):
            print(f"[ERROR] Неподдерживаемый формат: {file.filename}")
            return jsonify({'success': False, 'error': 'Неподдерживаемый формат файла'}), 400
        
        # Проверяем размер файла
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0)
        print(f"[DEBUG] Размер файла: {file_size} байт ({file_size / 1024 / 1024:.2f} MB)")
        
        if file_size > app.config['MAX_CONTENT_LENGTH']:
            return jsonify({'success': False, 'error': f'Файл слишком большой. Максимум: {app.config["MAX_CONTENT_LENGTH"] / 1024 / 1024 / 1024:.1f} GB'}), 400
        
        # Сохраняем загруженный файл
        file_id = str(uuid.uuid4())
        input_filename = secure_filename(file.filename)
        if '.' in input_filename:
            input_ext = input_filename.rsplit('.', 1)[1].lower()
        else:
            input_ext = 'mp4'
        
        input_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{file_id}_input.{input_ext}')
        output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{file_id}_output_720p.mp4')
        frames_dir = os.path.join(app.config['UPLOAD_FOLDER'], f'{file_id}_frames')
        
        print(f"[DEBUG] Сохранение файла в: {input_path}")
        print(f"[DEBUG] UPLOAD_FOLDER: {app.config['UPLOAD_FOLDER']}")
        print(f"[DEBUG] Папка существует: {os.path.exists(app.config['UPLOAD_FOLDER'])}")
        print(f"[DEBUG] Это директория: {os.path.isdir(app.config['UPLOAD_FOLDER']) if os.path.exists(app.config['UPLOAD_FOLDER']) else False}")
        
        # Убеждаемся, что папка существует и является директорией
        upload_folder = app.config['UPLOAD_FOLDER']
        if os.path.exists(upload_folder):
            if not os.path.isdir(upload_folder):
                # Если это файл, удаляем его и создаем директорию
                print(f"[WARNING] {upload_folder} существует как файл, удаляем и создаем директорию")
                try:
                    os.remove(upload_folder)
                    os.makedirs(upload_folder, exist_ok=True)
                except Exception as e:
                    print(f"[ERROR] Не удалось удалить файл и создать директорию: {e}")
                    return jsonify({'success': False, 'error': f'Ошибка создания директории: {str(e)}'}), 500
            else:
                # Убеждаемся, что директория существует (на случай если была удалена)
                os.makedirs(upload_folder, exist_ok=True)
        else:
            # Создаем директорию если её нет
            try:
                os.makedirs(upload_folder, exist_ok=True)
            except Exception as e:
                print(f"[ERROR] Не удалось создать директорию {upload_folder}: {e}")
                return jsonify({'success': False, 'error': f'Ошибка создания директории: {str(e)}'}), 500
        
        file.save(input_path)
        print(f"[DEBUG] Файл сохранен. Размер: {os.path.getsize(input_path)} байт")
        
        # Сжимаем видео до 720p
        print(f"[DEBUG] Начало сжатия видео...")
        success, error = compress_video(input_path, output_path, '720')
        if not success:
            print(f"[ERROR] Ошибка сжатия: {error}")
            if os.path.exists(input_path):
                os.remove(input_path)
            return jsonify({'success': False, 'error': error}), 500
        print(f"[DEBUG] Видео сжато. Размер: {os.path.getsize(output_path)} байт")
        
        # Извлекаем кадры
        print(f"[DEBUG] Начало извлечения кадров...")
        success, frames, error = extract_frames(output_path, frames_dir, interval_seconds=15)
        if not success:
            print(f"[ERROR] Ошибка извлечения кадров: {error}")
            return jsonify({'success': False, 'error': error}), 500
        print(f"[DEBUG] Извлечено кадров: {len(frames)}")
        
        # Формируем список кадров с URL
        frames_list = []
        # Определяем базовый URL сервера
        base_url = request.host_url.rstrip('/')
        if not base_url.startswith('http'):
            # Если host_url не содержит протокол, добавляем
            base_url = f"http://{base_url.rstrip('/')}"
        
        for idx, frame_path in enumerate(frames):
            frame_filename = os.path.basename(frame_path)
            # Формируем полный URL для кадра
            frame_url = f'{base_url}/admin/frame/{file_id}/{frame_filename}'
            frames_list.append({
                'filename': frame_filename,
                'url': frame_url,
                'local_path': frame_path,
                'index': idx + 1
            })
        
        return jsonify({
            'success': True,
            'video_id': file_id,
            'compressed_video_path': output_path,
            'frames': frames_list,
            'frames_count': len(frames_list)
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': f'Ошибка обработки: {str(e)}'}), 500

@app.route('/admin/extract-frames', methods=['POST'])
def admin_extract_frames():
    """Извлекает кадры из уже обработанного видео"""
    video_id = request.form.get('video_id')
    if not video_id:
        return jsonify({'success': False, 'error': 'video_id не указан'}), 400
    
    try:
        # Ищем сжатое видео
        output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{video_id}_output_720p.mp4')
        if not os.path.exists(output_path):
            return jsonify({'success': False, 'error': 'Видео не найдено'}), 404
        
        frames_dir = os.path.join(app.config['UPLOAD_FOLDER'], f'{video_id}_frames')
        
        # Извлекаем кадры
        success, frames, error = extract_frames(output_path, frames_dir, interval_seconds=15)
        if not success:
            return jsonify({'success': False, 'error': error}), 500
        
        # Формируем список кадров
        frames_list = []
        # Определяем базовый URL сервера
        base_url = request.host_url.rstrip('/')
        if not base_url.startswith('http'):
            # Если host_url не содержит протокол, добавляем
            base_url = f"http://{base_url.rstrip('/')}"
        
        for idx, frame_path in enumerate(frames):
            frame_filename = os.path.basename(frame_path)
            # Формируем полный URL для кадра
            frame_url = f'{base_url}/admin/frame/{video_id}/{frame_filename}'
            frames_list.append({
                'filename': frame_filename,
                'url': frame_url,
                'local_path': frame_path,
                'index': idx + 1
            })
        
        return jsonify({
            'success': True,
            'frames': frames_list,
            'frames_count': len(frames_list)
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': f'Ошибка извлечения кадров: {str(e)}'}), 500

@app.route('/admin/frame/<video_id>/<filename>')
def serve_admin_frame(video_id, filename):
    """Отдает кадр для админ-панели"""
    try:
        frame_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{video_id}_frames', filename)
        if os.path.exists(frame_path):
            return send_file(frame_path, mimetype='image/jpeg')
        else:
            return jsonify({'error': 'Файл не найден'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/admin/save-to-portfolio', methods=['POST'])
def admin_save_to_portfolio():
    """Сохраняет видео и обложку в Supabase Storage и создает запись в БД"""
    try:
        video_id = request.form.get('video_id')
        category = request.form.get('category')
        frame_path = request.form.get('frame_path')
        title = request.form.get('title', '').strip()
        description = request.form.get('description', '').strip()
        format_type = request.form.get('format', '9-16')
        
        if not video_id or not category or not frame_path or not title:
            return jsonify({'success': False, 'error': 'Не все обязательные поля заполнены'}), 400
        
        if category not in CATEGORY_FOLDER_MAP:
            return jsonify({'success': False, 'error': f'Неизвестная категория: {category}'}), 400
        
        supabase = get_supabase_client()
        if not supabase:
            app.logger.error("Supabase клиент не создан. Проверьте SUPABASE_URL и SUPABASE_KEY")
            return jsonify({'success': False, 'error': 'Supabase не настроен. Проверьте SUPABASE_URL и SUPABASE_KEY'}), 500
        
        # Пути к файлам
        compressed_video_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{video_id}_output_720p.mp4')
        
        # Проверяем существование файлов
        if not os.path.exists(compressed_video_path):
            return jsonify({'success': False, 'error': 'Сжатое видео не найдено'}), 404
        
        # Определяем путь к кадру
        if frame_path.startswith('/admin/frame/'):
            # Извлекаем путь из URL
            parts = frame_path.replace('/admin/frame/', '').split('/')
            if len(parts) >= 2:
                frame_video_id = parts[0]
                frame_filename = parts[1]
                actual_frame_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{frame_video_id}_frames', frame_filename)
            else:
                actual_frame_path = frame_path
        else:
            actual_frame_path = frame_path
        
        if not os.path.exists(actual_frame_path):
            return jsonify({'success': False, 'error': 'Обложка не найдена'}), 404
        
        # Формируем пути в Storage
        folder_name = CATEGORY_FOLDER_MAP[category]
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        safe_title = secure_filename(title)[:50]  # Ограничиваем длину
        
        # Формируем имя файла с префиксом compressed_720p_, как в старых файлах
        video_filename = f'compressed_720p_{safe_title}.mp4'
        video_storage_path = f'{folder_name}/{video_filename}'
        
        # Путь к изображению должен включать категорию, как в старых файлах
        image_filename = f'{safe_title}.jpg'
        image_storage_path = f'images/{folder_name}/{image_filename}'
        
        video_public_url, error = upload_to_supabase_storage(compressed_video_path, video_storage_path, 'portfolio')
        if error:
            app.logger.error(f"Ошибка загрузки видео: {error}")
            return jsonify({'success': False, 'error': f'Ошибка загрузки видео: {error}'}), 500
        
        image_public_url, error = upload_to_supabase_storage(actual_frame_path, image_storage_path, 'portfolio')
        if error:
            app.logger.error(f"Ошибка загрузки обложки: {error}")
            return jsonify({'success': False, 'error': f'Ошибка загрузки обложки: {error}'}), 500
        
        # Формируем полные пути для сохранения в БД
        # Формат: /storage/v1/object/public/portfolio/{folder}/{filename}
        supabase_url = app.config.get('SUPABASE_URL', '').rstrip('/')
        
        # Извлекаем путь из полного URL или формируем полный путь
        if video_public_url.startswith('/storage/v1/object/public/'):
            # Уже полный путь
            video_relative_path = video_public_url
        elif video_public_url.startswith(supabase_url):
            # Извлекаем путь после базового URL
            video_relative_path = video_public_url.replace(supabase_url, "")
        else:
            # Формируем полный путь в нужном формате
            video_relative_path = f"/storage/v1/object/public/portfolio/{video_storage_path}"
        
        if image_public_url.startswith('/storage/v1/object/public/'):
            # Уже полный путь
            image_relative_path = image_public_url
        elif image_public_url.startswith(supabase_url):
            # Извлекаем путь после базового URL
            image_relative_path = image_public_url.replace(supabase_url, "")
        else:
            # Формируем полный путь в нужном формате
            image_relative_path = f"/storage/v1/object/public/portfolio/{image_storage_path}"
        
        # Определяем размеры на основе формата
        width = 238
        height = 368
        if format_type == '16-9':
            width = 640
            height = 360
        elif format_type == '1-1':
            width = 400
            height = 400
        
        # Получаем максимальный order_index для категории
        try:
            result = supabase.table('portfolio').select('order_index').eq('category', category).order('order_index', desc=True).limit(1).execute()
            max_order = 0
            if result.data and len(result.data) > 0:
                max_order = result.data[0].get('order_index', 0)
            order_index = max_order + 1
        except:
            order_index = 0
        
        # Создаем запись в БД
        portfolio_data = {
            'title': title,
            'description': description,
            'video_url': video_relative_path,  # Относительный путь: Reklamniye/compressed_720p_title.mp4
            'image_url': image_relative_path,   # Относительный путь: images/Reklamniye/title.jpg
            'category': category,
            'width': width,
            'height': height,
            'format': format_type,
            'order_index': order_index,
            'is_published': True
        }
        
        result = supabase.table('portfolio').insert(portfolio_data).execute()
        
        if hasattr(result, 'data') and result.data:
            # Удаляем временные файлы в фоне
            def cleanup():
                import time
                time.sleep(5)
                try:
                    if os.path.exists(compressed_video_path):
                        os.remove(compressed_video_path)
                    frames_dir = os.path.join(app.config['UPLOAD_FOLDER'], f'{video_id}_frames')
                    if os.path.exists(frames_dir):
                        shutil.rmtree(frames_dir)
                    input_path = os.path.join(app.config['UPLOAD_FOLDER'], f'{video_id}_input.*')
                    for path in glob.glob(input_path):
                        if os.path.exists(path):
                            os.remove(path)
                except:
                    pass
            
            import threading
            threading.Thread(target=cleanup, daemon=True).start()
            
            return jsonify({
                'success': True,
                'message': 'Видео успешно добавлено в портфолио',
                'data': result.data[0] if result.data else None
            })
        else:
            return jsonify({'success': False, 'error': 'Ошибка создания записи в БД'}), 500
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'error': f'Ошибка сохранения: {str(e)}'}), 500

if __name__ == '__main__':
    # Проверяем наличие FFmpeg при запуске
    try:
        subprocess.run(['ffmpeg', '-version'], 
                      stdout=subprocess.PIPE, 
                      stderr=subprocess.PIPE, 
                      check=True, 
                      timeout=5)
        print("[OK] FFmpeg найден")
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("[WARNING] ВНИМАНИЕ: FFmpeg не найден!")
        print("Установите FFmpeg для работы приложения:")
        print("Windows: https://ffmpeg.org/download.html")
        print("Linux: sudo apt-get install ffmpeg")
        print("macOS: brew install ffmpeg")
    except Exception as e:
        print(f"[ERROR] Ошибка при проверке FFmpeg: {e}")
    
    # В Docker используем production режим
    debug_mode = os.environ.get('FLASK_ENV', 'development') != 'production'
    app.run(debug=debug_mode, host='0.0.0.0', port=5000)

