@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo Установка и запуск Редактора
echo ========================================
echo.

REM Проверка Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Python не найден!
    echo Установите Python с https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [OK] Python найден
python --version
echo.

REM Установка зависимостей
echo Установка зависимостей Python...
python -m pip install -q --upgrade pip
python -m pip install Flask Werkzeug boto3 supabase
if errorlevel 1 (
    echo [ОШИБКА] Не удалось установить зависимости
    pause
    exit /b 1
)

echo [OK] Зависимости установлены
echo.

REM Проверка FFmpeg
echo Проверка FFmpeg...
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo [ВНИМАНИЕ] FFmpeg не найден - некоторые функции могут не работать
    echo Установите FFmpeg и добавьте в PATH
) else (
    echo [OK] FFmpeg найден
)
echo.

REM Создание папки для кадров
if not exist "static\frames" mkdir "static\frames"

REM Запуск сервера
echo ========================================
echo Запуск сервера...
echo ========================================
echo.
echo Сервер будет доступен по адресу: http://localhost:5000
echo.
echo Нажмите Ctrl+C для остановки сервера
echo ========================================
echo.

python app.py

pause

