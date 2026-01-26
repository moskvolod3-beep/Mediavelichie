/**
 * Supabase Configuration - Пример
 * 
 * Скопируйте этот файл в config.js и заполните реальными значениями
 */

// ВАЖНО: Замените эти значения на ваши реальные данные из Supabase Dashboard
export const SUPABASE_CONFIG = {
    url: 'YOUR_SUPABASE_URL', // Например: 'https://xxxxx.supabase.co'
    anonKey: 'YOUR_SUPABASE_ANON_KEY' // Публичный anon key из настроек проекта
};

// Имена таблиц в базе данных
export const TABLES = {
    ORDERS: 'orders',
    PORTFOLIO: 'portfolio',
    REVIEWS: 'reviews',
    PROJECTS: 'projects'
};
