@echo off
chcp 65001 >nul
echo Добавление C:\ffmpeg\bin в PATH...
echo.

REM Проверяем права администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ОШИБКА: Этот скрипт нужно запускать от имени администратора!
    echo.
    echo Щелкните правой кнопкой на файл и выберите
    echo "Запуск от имени администратора"
    echo.
    pause
    exit /b 1
)

REM Проверяем существование папки
if not exist "C:\ffmpeg\bin" (
    echo ОШИБКА: Папка C:\ffmpeg\bin не найдена!
    echo.
    echo Убедитесь, что FFmpeg установлен в C:\ffmpeg
    echo.
    pause
    exit /b 1
)

REM Получаем текущий PATH
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set SYSTEM_PATH=%%b

REM Проверяем, не добавлен ли уже
echo %SYSTEM_PATH% | findstr /C:"C:\ffmpeg\bin" >nul
if %errorLevel% equ 0 (
    echo C:\ffmpeg\bin уже в PATH
    pause
    exit /b 0
)

REM Добавляем в PATH
setx /M PATH "%SYSTEM_PATH%;C:\ffmpeg\bin" >nul
if %errorLevel% equ 0 (
    echo.
    echo ========================================
    echo ✓ C:\ffmpeg\bin успешно добавлен в PATH
    echo ========================================
    echo.
    echo ВАЖНО: Перезапустите командную строку или
    echo перезагрузите компьютер для применения изменений
    echo.
) else (
    echo ОШИБКА: Не удалось добавить в PATH
    echo Попробуйте добавить вручную через "Переменные среды"
)

pause








