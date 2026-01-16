@echo off
chcp 65001 >nul
echo ========================================
echo Установка FFmpeg для Windows
echo ========================================
echo.
echo Этот скрипт скачает и установит FFmpeg
echo.
echo ВАЖНО: Для работы нужны права администратора!
echo.

REM Проверяем права администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ОШИБКА: Этот скрипт нужно запускать от имени администратора!
    echo Щелкните правой кнопкой и выберите "Запуск от имени администратора"
    pause
    exit /b 1
)

echo [1/4] Скачивание FFmpeg...
set FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip
set FFMPEG_ZIP=%TEMP%\ffmpeg.zip
set FFMPEG_DIR=C:\ffmpeg

curl -L -o "%FFMPEG_ZIP%" "%FFMPEG_URL%"
if errorlevel 1 (
    echo ОШИБКА при скачивании FFmpeg
    echo Скачайте вручную с https://ffmpeg.org/download.html
    pause
    exit /b 1
)

echo [2/4] Распаковка...
if exist "%FFMPEG_DIR%" rmdir /s /q "%FFMPEG_DIR%"
mkdir "%FFMPEG_DIR%"

powershell -command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%TEMP%\ffmpeg_temp' -Force"
for /d %%i in ("%TEMP%\ffmpeg_temp\ffmpeg-*") do (
    xcopy /E /I /Y "%%i\*" "%FFMPEG_DIR%"
)

echo [3/4] Добавление в PATH...
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do set SYSTEM_PATH=%%b
echo %SYSTEM_PATH% | findstr /C:"%FFMPEG_DIR%\bin" >nul
if errorlevel 1 (
    setx /M PATH "%SYSTEM_PATH%;%FFMPEG_DIR%\bin"
    echo PATH обновлен
) else (
    echo FFmpeg уже в PATH
)

echo [4/4] Очистка...
del "%FFMPEG_ZIP%"
rmdir /s /q "%TEMP%\ffmpeg_temp"

echo.
echo ========================================
echo Установка завершена!
echo ========================================
echo.
echo ВАЖНО: Перезагрузите компьютер или перезапустите командную строку
echo для применения изменений PATH
echo.
pause








