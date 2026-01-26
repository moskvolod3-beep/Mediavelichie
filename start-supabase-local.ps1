# Скрипт для запуска локального Supabase
# Требования: Docker Desktop должен быть запущен

Write-Host "Проверка Docker..." -ForegroundColor Cyan
docker ps | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ОШИБКА: Docker не запущен или недоступен!" -ForegroundColor Red
    Write-Host "Пожалуйста, запустите Docker Desktop и попробуйте снова." -ForegroundColor Yellow
    exit 1
}

Write-Host "Docker работает!" -ForegroundColor Green

Write-Host "`nЗапуск локального Supabase..." -ForegroundColor Cyan
supabase start

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Supabase успешно запущен локально!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`nДля получения информации о подключении выполните:" -ForegroundColor Cyan
    Write-Host "  supabase status" -ForegroundColor Yellow
    Write-Host "`nДля остановки Supabase выполните:" -ForegroundColor Cyan
    Write-Host "  supabase stop" -ForegroundColor Yellow
} else {
    Write-Host "`nОшибка при запуске Supabase!" -ForegroundColor Red
    exit 1
}
