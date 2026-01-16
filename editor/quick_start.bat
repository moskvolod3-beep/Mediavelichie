@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Редактор разрешения видео

echo ========================================
echo Редактор разрешения видео
echo ========================================
echo.

REM Проверка FFmpeg
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo [X] FFmpeg не найден
    echo.
    echo Для установки FFmpeg:
    echo 1. Запустите install_ffmpeg.bat от имени администратора
    echo 2. Или установите вручную (см. README.md)
    echo.
    echo Продолжить без FFmpeg? (приложение не будет работать)
    pause
) else (
    echo [✓] FFmpeg найден
)

echo.
echo Установка зависимостей Python...
python -m pip install -q Flask Werkzeug
if errorlevel 1 (
    echo ОШИБКА: Не удалось установить зависимости
    echo Убедитесь, что Python установлен
    pause
    exit /b 1
)

echo [✓] Зависимости установлены
echo.
echo Запуск сервера...
echo Откройте в браузере: http://localhost:5000
echo.
echo Нажмите Ctrl+C для остановки сервера
echo.

cd /d "%~dp0"
python app.py


