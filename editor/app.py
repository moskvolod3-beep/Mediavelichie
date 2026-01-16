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

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 2 * 1024 * 1024 * 1024  # 2GB максимум
# Используем диск D для временных файлов, если доступен, иначе системную временную папку
if os.path.exists('D:\\'):
    app.config['UPLOAD_FOLDER'] = os.path.join('D:\\', 'Mediavelichia', 'editor', 'temp')
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
else:
    app.config['UPLOAD_FOLDER'] = tempfile.gettempdir()
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
        input_ext = input_filename.rsplit('.', 1)[1].lower()
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
        input_ext = input_filename.rsplit('.', 1)[1].lower()
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
    
    app.run(debug=True, host='0.0.0.0', port=5000)

