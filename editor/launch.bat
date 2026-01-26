@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo Редактор разрешения видео
echo ========================================
echo.

REM Установка зависимостей
echo [1/3] Проверка зависимостей...
python -m pip install -q Flask Werkzeug boto3 supabase 2>nul
if %errorLevel% neq 0 (
    echo Установка зависимостей...
    python -m pip install Flask Werkzeug boto3 supabase
)
echo [OK] Зависимости готовы
echo.

REM Проверка FFmpeg
echo [2/3] Проверка FFmpeg...
ffmpeg -version >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] FFmpeg найден
) else (
    echo [ВНИМАНИЕ] FFmpeg не найден - приложение может не работать
)
echo.

REM Запуск сервера
echo [3/3] Запуск сервера...
echo.
echo ========================================
echo Сервер запущен!
echo ========================================
echo.
echo Откройте в браузере: http://localhost:5000
echo.
echo Нажмите Ctrl+C для остановки сервера
echo.

python app.py

pause






