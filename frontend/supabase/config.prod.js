/**
 * Supabase Configuration для продакшена
 * 
 * Этот файл используется при сборке Docker образа.
 * Значения подставляются из переменных окружения через build-time подстановку.
 * 
 * Для локальной разработки используйте config.js
 */

// Значения будут заменены при сборке Docker образа через sed
export const SUPABASE_CONFIG = {
    url: 'SUPABASE_URL_PLACEHOLDER', // Заменится на ${SUPABASE_URL} при сборке
    anonKey: 'SUPABASE_ANON_KEY_PLACEHOLDER' // Заменится на ${SUPABASE_ANON_KEY} при сборке
};

// Имена таблиц в базе данных
export const TABLES = {
    ORDERS: 'orders',
    PORTFOLIO: 'portfolio',
    REVIEWS: 'reviews',
    PROJECTS: 'projects'
};
