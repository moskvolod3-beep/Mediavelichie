@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo Запуск Редактора разрешения видео
echo ========================================
echo.

REM Проверка Python - пробуем разные команды
set PYTHON_CMD=
python --version >nul 2>&1
if %errorLevel% equ 0 (
    set PYTHON_CMD=python
    goto :found_python
)

py --version >nul 2>&1
if %errorLevel% equ 0 (
    set PYTHON_CMD=py
    goto :found_python
)

python3 --version >nul 2>&1
if %errorLevel% equ 0 (
    set PYTHON_CMD=python3
    goto :found_python
)

REM Python не найден
echo [ОШИБКА] Python не найден!
echo.
echo Python не установлен или не добавлен в PATH.
echo.
echo Для установки Python:
echo 1. Скачайте с https://www.python.org/downloads/
echo 2. При установке ОБЯЗАТЕЛЬНО отметьте "Add Python to PATH"
echo 3. Перезагрузите компьютер после установки
echo.
echo Или добавьте Python в PATH вручную.
echo.
pause
exit /b 1

:found_python
echo [OK] Python найден
%PYTHON_CMD% --version
echo.

REM Установка зависимостей
echo Установка зависимостей...
%PYTHON_CMD% -m pip install -q Flask Werkzeug boto3 supabase 2>nul
%PYTHON_CMD% -m pip install Flask Werkzeug boto3 supabase >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Не удалось установить зависимости
    pause
    exit /b 1
)
echo [OK] Зависимости установлены

REM Запуск сервера
echo.
echo ========================================
echo Сервер запущен!
echo ========================================
echo.
echo Откройте в браузере: http://localhost:5000
echo.
echo Нажмите Ctrl+C для остановки сервера
echo ========================================
echo.

%PYTHON_CMD% app.py

