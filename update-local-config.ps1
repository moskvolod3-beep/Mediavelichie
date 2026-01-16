# Скрипт для обновления конфигурации для локальной разработки
# Автоматически получает данные из supabase status и обновляет config.js

Write-Host "Получение статуса локального Supabase..." -ForegroundColor Cyan

$status = supabase status --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ОШИБКА: Supabase не запущен!" -ForegroundColor Red
    Write-Host "Запустите Supabase командой: supabase start" -ForegroundColor Yellow
    exit 1
}

# Парсим JSON статус
try {
    $statusJson = $status | ConvertFrom-Json
} catch {
    Write-Host "Не удалось получить JSON статус, используем текстовый вывод..." -ForegroundColor Yellow
    $statusText = supabase status
    
    # Извлекаем значения из текстового вывода
    $apiUrl = ($statusText | Select-String -Pattern "API URL:\s*(.+)").Matches.Groups[1].Value.Trim()
    $anonKey = ($statusText | Select-String -Pattern "anon key:\s*(.+)").Matches.Groups[1].Value.Trim()
    
    if (-not $apiUrl -or -not $anonKey) {
        Write-Host "Не удалось извлечь данные из статуса." -ForegroundColor Red
        Write-Host "Выполните 'supabase status' вручную и обновите config.js" -ForegroundColor Yellow
        exit 1
    }
} else {
    $apiUrl = $statusJson.Api.Url
    $anonKey = $statusJson.Api.AnonKey
}

Write-Host "`nНайденные значения:" -ForegroundColor Green
Write-Host "  API URL: $apiUrl" -ForegroundColor Cyan
Write-Host "  Anon Key: $anonKey" -ForegroundColor Cyan

# Создаем локальный конфиг файл
$configContent = @"
/**
 * Supabase Configuration для локальной разработки
 * Автоматически сгенерировано скриптом update-local-config.ps1
 * 
 * ВАЖНО: Этот файл используется только для локальной разработки!
 * Для продакшена используйте supabase/config.js
 */

export const SUPABASE_CONFIG = {
    url: '$apiUrl',
    anonKey: '$anonKey'
};

// Имена таблиц в базе данных
export const TABLES = {
    ORDERS: 'orders',
    PORTFOLIO: 'portfolio',
    REVIEWS: 'reviews',
    PROJECTS: 'projects'
};
"@

$configPath = "supabase\config.local.js"
$configContent | Out-File -FilePath $configPath -Encoding UTF8

Write-Host "`nКонфигурация сохранена в: $configPath" -ForegroundColor Green

# Обновляем supabase-client.js для использования локального конфига в dev режиме
Write-Host "`nДля использования локального конфига в коде:" -ForegroundColor Yellow
Write-Host "  Измените импорт в js/supabase-client.js:" -ForegroundColor Yellow
Write-Host "    import { SUPABASE_CONFIG, TABLES } from '../supabase/config.local.js';" -ForegroundColor Cyan

Write-Host "`nГотово!" -ForegroundColor Green
