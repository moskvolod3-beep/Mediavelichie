@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ========================================
echo Проверка готовности системы
echo ========================================
echo.
echo Рабочая директория: %CD%
echo.

set ALL_OK=1

REM Проверка FFmpeg
echo [1/4] Проверка FFmpeg...
ffmpeg -version >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] FFmpeg установлен
    ffmpeg -version | findstr /C:"ffmpeg version"
) else (
    echo [ОШИБКА] FFmpeg не найден!
    echo    Установите FFmpeg: https://ffmpeg.org/download.html
    echo    Или запустите install_ffmpeg.bat
    set ALL_OK=0
)
echo.

REM Проверка Python
echo [2/4] Проверка Python...
python --version >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Python установлен
    python --version
) else (
    echo [ОШИБКА] Python не найден!
    echo    Установите Python: https://www.python.org/downloads/
    set ALL_OK=0
)
echo.

REM Проверка Flask
echo [3/4] Проверка Flask...
python -c "import flask" >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Flask установлен
    python -c "import flask; print('   Версия:', flask.__version__)"
) else (
    echo [ВНИМАНИЕ] Flask не установлен, устанавливаю...
    python -m pip install Flask Werkzeug -q
    if %errorLevel% equ 0 (
        echo [OK] Flask установлен
    ) else (
        echo [ОШИБКА] Не удалось установить Flask
        set ALL_OK=0
    )
)
echo.

REM Проверка файлов проекта
echo [4/4] Проверка файлов проекта...
if exist "app.py" (
    echo [OK] app.py найден
) else (
    echo [ОШИБКА] app.py не найден!
    set ALL_OK=0
)

if exist "templates\index.html" (
    echo [OK] templates\index.html найден
) else (
    echo [ОШИБКА] templates\index.html не найден!
    set ALL_OK=0
)

if exist "static\style.css" (
    echo [OK] static\style.css найден
) else (
    echo [ОШИБКА] static\style.css не найден!
    set ALL_OK=0
)

if exist "static\script.js" (
    echo [OK] static\script.js найден
) else (
    echo [ОШИБКА] static\script.js не найден!
    set ALL_OK=0
)
echo.

REM Итоговый результат
echo ========================================
if %ALL_OK% equ 1 (
    echo [✓] ВСЕ ГОТОВО К ЗАПУСКУ!
    echo ========================================
    echo.
    echo Для запуска сервера:
    echo   1. Запустите: run_server.bat
    echo   2. Откройте в браузере: http://localhost:5000
    echo.
) else (
    echo [✗] ОБНАРУЖЕНЫ ПРОБЛЕМЫ
    echo ========================================
    echo.
    echo Исправьте указанные ошибки и запустите проверку снова.
    echo.
)
pause

