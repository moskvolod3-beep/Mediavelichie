/**
 * Supabase Configuration
 * 
 * Для использования:
 * 1. Создайте проект на https://supabase.com
 * 2. Скопируйте URL и anon key из настроек проекта
 * 3. Замените значения ниже на ваши
 */

// Конфигурация для локального Supabase
// Для продакшена замените на значения из Supabase Dashboard
export const SUPABASE_CONFIG = {
    url: 'http://127.0.0.1:54321', // Локальный Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' // Anon key для локального Supabase
};

// Имена таблиц в базе данных
export const TABLES = {
    ORDERS: 'orders',
    PORTFOLIO: 'portfolio',
    REVIEWS: 'reviews',
    PROJECTS: 'projects'
};
