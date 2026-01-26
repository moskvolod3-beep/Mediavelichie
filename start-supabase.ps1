# Скрипт для запуска Supabase локально
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Запуск локального Supabase" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка Docker
Write-Host "Проверка Docker Desktop..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker Desktop работает" -ForegroundColor Green
    } else {
        throw "Docker не доступен"
    }
} catch {
    Write-Host "Docker Desktop не запущен!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Пожалуйста:" -ForegroundColor Yellow
    Write-Host "1. Запустите Docker Desktop" -ForegroundColor White
    Write-Host "2. Дождитесь полной загрузки Docker" -ForegroundColor White
    Write-Host "3. Запустите этот скрипт снова" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Переход в директорию проекта
Set-Location $PSScriptRoot

# Проверка статуса Supabase
Write-Host ""
Write-Host "Проверка статуса Supabase..." -ForegroundColor Yellow
$status = supabase status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Supabase уже запущен" -ForegroundColor Green
    Write-Host ""
    supabase status
} else {
    Write-Host "Запуск Supabase..." -ForegroundColor Yellow
    Write-Host "(Это может занять несколько минут при первом запуске)" -ForegroundColor Gray
    Write-Host ""
    
    supabase start
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Supabase успешно запущен!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        # Получаем статус для отображения ссылок
        Write-Host "Информация о подключении:" -ForegroundColor Cyan
        Write-Host ""
        supabase status
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Важные ссылки:" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        # Извлекаем ссылки из статуса
        $statusOutput = supabase status
        $studioUrl = ($statusOutput | Select-String -Pattern "Studio URL:\s*(.+)").Matches.Groups[1].Value.Trim()
        $apiUrl = ($statusOutput | Select-String -Pattern "API URL:\s*(.+)").Matches.Groups[1].Value.Trim()
        
        if ($studioUrl) {
            Write-Host ""
            Write-Host "Supabase Studio:" -ForegroundColor Yellow
            Write-Host "   $studioUrl" -ForegroundColor White
            Write-Host "   (Веб-интерфейс для управления БД)" -ForegroundColor Gray
            Write-Host ""
        }
        
        if ($apiUrl) {
            Write-Host "API URL:" -ForegroundColor Yellow
            Write-Host "   $apiUrl" -ForegroundColor White
            Write-Host "   (Используйте для подключения в коде)" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Обновляем конфигурацию
        Write-Host "Обновление локальной конфигурации..." -ForegroundColor Yellow
        if (Test-Path "update-local-config.ps1") {
            & ".\update-local-config.ps1"
        } else {
            Write-Host "Скрипт update-local-config.ps1 не найден" -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "Ошибка при запуске Supabase" -ForegroundColor Red
        Write-Host "Попробуйте выполнить: supabase start --debug" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Для остановки Supabase выполните: supabase stop" -ForegroundColor Gray
Write-Host ""
