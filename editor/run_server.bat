@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo Запуск сервера...
echo Откройте в браузере: http://localhost:5000
echo.
echo Нажмите Ctrl+C для остановки
echo.

python app.py
pause


