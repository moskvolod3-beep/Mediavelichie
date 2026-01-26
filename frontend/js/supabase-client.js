/**
 * Supabase Client для работы с базой данных
 * 
 * Этот модуль предоставляет функции для взаимодействия с Supabase
 */

// Используем CDN для Supabase клиента
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

// Импортируем конфигурацию
import { SUPABASE_CONFIG, TABLES } from '../supabase/config.js';

// Инициализация Supabase клиента
let supabaseClient = null;

/**
 * Инициализирует Supabase клиент
 */
export function initSupabase() {
    if (!SUPABASE_CONFIG.url || SUPABASE_CONFIG.url === 'YOUR_SUPABASE_URL') {
        console.warn('Supabase не настроен. Пожалуйста, укажите URL и ключ в supabase/config.js');
        return null;
    }
    
    if (!SUPABASE_CONFIG.anonKey || SUPABASE_CONFIG.anonKey === 'YOUR_SUPABASE_ANON_KEY') {
        console.warn('Supabase не настроен. Пожалуйста, укажите anon key в supabase/config.js');
        return null;
    }
    
    try {
        supabaseClient = createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
        console.log('Supabase клиент инициализирован');
        return supabaseClient;
    } catch (error) {
        console.error('Ошибка инициализации Supabase:', error);
        return null;
    }
}

/**
 * Получает экземпляр Supabase клиента
 */
export function getSupabaseClient() {
    if (!supabaseClient) {
        return initSupabase();
    }
    return supabaseClient;
}

// ============================================
// ФУНКЦИИ ДЛЯ РАБОТЫ С ЗАЯВКАМИ (ORDERS)
// ============================================

/**
 * Создает новую заявку
 * @param {Object} orderData - Данные заявки
 * @param {string} orderData.name - Имя клиента
 * @param {string} orderData.phone - Телефон клиента
 * @param {string} orderData.message - Сообщение
 * @param {boolean} orderData.privacy_accepted - Согласие на обработку данных
 * @returns {Promise<Object>} Результат операции
 */
export async function createOrder(orderData) {
    const client = getSupabaseClient();
    if (!client) {
        return { success: false, error: 'Supabase не инициализирован' };
    }
    
    try {
        const { data, error } = await client
            .from(TABLES.ORDERS)
            .insert([{
                name: orderData.name,
                phone: orderData.phone,
                message: orderData.message || '',
                privacy_accepted: orderData.privacy_accepted || false
            }])
            .select()
            .single();
        
        if (error) {
            console.error('Ошибка создания заявки:', error);
            return { success: false, error: error.message };
        }
        
        return { success: true, data };
    } catch (error) {
        console.error('Исключение при создании заявки:', error);
        return { success: false, error: error.message };
    }
}

// ============================================
// ФУНКЦИИ ДЛЯ РАБОТЫ С ПОРТФОЛИО
// ============================================

/**
 * Формирует публичный URL для файла из Supabase Storage
 * @param {string} filePath - Путь к файлу в Storage (например, 'category/video.mp4' или полный URL)
 * @param {string} bucketName - Имя бакета (по умолчанию 'portfolio')
 * @returns {string} Публичный URL файла из Supabase Storage
 */
export function getStoragePublicUrl(filePath, bucketName = 'portfolio') {
    if (!filePath) {
        return null;
    }
    
    const client = getSupabaseClient();
    if (!client || !SUPABASE_CONFIG.url) {
        console.warn('Supabase не инициализирован, возвращаем исходный путь');
        return filePath;
    }
    
    // Если уже полный URL (http/https), возвращаем как есть
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        return filePath;
    }
    
    try {
        // Если путь уже содержит полный путь Storage API (/storage/v1/object/public/...)
        if (filePath.startsWith('/storage/v1/object/public/')) {
            // Просто добавляем базовый URL Supabase
            const baseUrl = SUPABASE_CONFIG.url.replace(/\/$/, ''); // Убираем завершающий слеш если есть
            return `${baseUrl}${filePath}`;
        }
        
        // Убираем начальный слеш, если есть
        let cleanPath = filePath.startsWith('/') ? filePath.slice(1) : filePath;
        
        // Если путь уже содержит имя бакета в начале, убираем его
        if (cleanPath.startsWith(`${bucketName}/`)) {
            cleanPath = cleanPath.replace(`${bucketName}/`, '');
        }
        
        // Формируем публичный URL для Supabase Storage
        const baseUrl = SUPABASE_CONFIG.url.replace(/\/$/, '');
        const publicUrl = `${baseUrl}/storage/v1/object/public/${bucketName}/${cleanPath}`;
        return publicUrl;
    } catch (error) {
        console.error('Ошибка формирования URL Storage:', error);
        return filePath;
    }
}

/**
 * Получает все опубликованные работы портфолио
 * @param {string} category - Категория для фильтрации (опционально)
 * @returns {Promise<Array>} Массив работ портфолио
 */
export async function getPortfolio(category = null) {
    const client = getSupabaseClient();
    if (!client) {
        console.warn('Supabase не инициализирован, возвращаем пустой массив');
        return [];
    }
    
    try {
        let query = client
            .from(TABLES.PORTFOLIO)
            .select('*')
            .eq('is_published', true)
            .order('order_index', { ascending: true });
        
        if (category && category !== 'all') {
            query = query.eq('category', category);
        }
        
        const { data, error } = await query;
        
        if (error) {
            console.error('Ошибка загрузки портфолио:', error);
            return [];
        }
        
        // Обрабатываем данные: если video_url или image_url указывают на Storage, формируем публичный URL
        if (data && Array.isArray(data)) {
            return data.map(item => {
                // Если video_url есть и это путь в Storage (не полный URL), формируем публичный URL
                if (item.video_url && !item.video_url.startsWith('http')) {
                    // Используем бакет 'portfolio' где хранятся видео по категориям
                    const bucket = 'portfolio';
                    const originalUrl = item.video_url;
                    item.video_url = getStoragePublicUrl(item.video_url, bucket);
                    
                    // Логируем только если URL изменился
                    if (originalUrl !== item.video_url) {
                        console.log(`Преобразовано видео URL: ${originalUrl} -> ${item.video_url}`);
                    }
                }
                
                // Обрабатываем image_url, если он указывает на Storage
                if (item.image_url && !item.image_url.startsWith('http') && item.image_url.startsWith('/storage/')) {
                    const bucket = 'portfolio';
                    const originalImageUrl = item.image_url;
                    item.image_url = getStoragePublicUrl(item.image_url, bucket);
                    
                    if (originalImageUrl !== item.image_url) {
                        console.log(`Преобразовано изображение URL: ${originalImageUrl} -> ${item.image_url}`);
                    }
                }
                
                return item;
            });
        }
        
        return data || [];
    } catch (error) {
        console.error('Исключение при загрузке портфолио:', error);
        return [];
    }
}

/**
 * Получает все работы портфолио (включая скрытые) для админ-панели
 * @returns {Promise<Array>} Массив всех работ портфолио
 */
export async function getAllPortfolioItems() {
    const client = getSupabaseClient();
    if (!client) {
        console.warn('Supabase не инициализирован, возвращаем пустой массив');
        return [];
    }
    
    try {
        const { data, error } = await client
            .from(TABLES.PORTFOLIO)
            .select('*')
            .order('created_at', { ascending: false });
        
        if (error) {
            console.error('Ошибка загрузки портфолио:', error);
            return [];
        }
        
        console.log('Загружено работ из портфолио:', data?.length || 0);
        
        // Обрабатываем URL для отображения
        if (data && Array.isArray(data)) {
            return data.map(item => {
                // Обрабатываем image_url - проверяем все варианты путей
                if (item.image_url) {
                    if (!item.image_url.startsWith('http')) {
                        // Если путь начинается с /storage/, используем его как есть
                        if (item.image_url.startsWith('/storage/')) {
                            item.image_url = getStoragePublicUrl(item.image_url, 'portfolio');
                        } else {
                            // Иначе формируем полный путь
                            item.image_url = getStoragePublicUrl(item.image_url, 'portfolio');
                        }
                    }
                }
                
                // Обрабатываем video_url аналогично
                if (item.video_url && !item.video_url.startsWith('http')) {
                    item.video_url = getStoragePublicUrl(item.video_url, 'portfolio');
                }
                
                return item;
            });
        }
        
        return data || [];
    } catch (error) {
        console.error('Исключение при загрузке портфолио:', error);
        return [];
    }
}

/**
 * Обновляет работу портфолио
 * @param {string} id - ID работы
 * @param {Object} updates - Объект с полями для обновления
 * @returns {Promise<Object>} Результат операции
 */
export async function updatePortfolioItem(id, updates) {
    const client = getSupabaseClient();
    if (!client) {
        return { success: false, error: 'Supabase не инициализирован' };
    }
    
    try {
        // Убеждаемся, что обновляем только допустимые поля
        const allowedFields = ['title', 'description', 'format', 'category', 'is_published', 'order_index'];
        const filteredUpdates = {};
        for (const key in updates) {
            if (allowedFields.includes(key)) {
                filteredUpdates[key] = updates[key];
            }
        }
        
        console.log('Обновление работы:', id, filteredUpdates);
        
        // Сначала обновляем без select, чтобы избежать ошибки 406
        const { error: updateError } = await client
            .from(TABLES.PORTFOLIO)
            .update(filteredUpdates)
            .eq('id', id);
        
        if (updateError) {
            console.error('Ошибка обновления работы:', updateError);
            console.error('Код ошибки:', updateError.code);
            console.error('Детали ошибки:', JSON.stringify(updateError, null, 2));
            return { success: false, error: updateError.message || 'Неизвестная ошибка обновления' };
        }
        
        // Если обновление прошло успешно, получаем данные отдельным запросом
        const { data: updatedData, error: fetchError } = await client
            .from(TABLES.PORTFOLIO)
            .select('*')
            .eq('id', id)
            .maybeSingle();
        
        if (fetchError) {
            console.warn('Не удалось получить обновленные данные:', fetchError);
            // Обновление прошло, но не удалось получить данные - это не критично
            return { success: true, data: null };
        }
        
        console.log('Работа успешно обновлена:', updatedData);
        return { success: true, data: updatedData };
    } catch (error) {
        console.error('Исключение при обновлении работы:', error);
        return { success: false, error: error.message || 'Неизвестная ошибка' };
    }
}

/**
 * Удаляет работу портфолио
 * @param {string} id - ID работы
 * @returns {Promise<Object>} Результат операции
 */
export async function deletePortfolioItem(id) {
    const client = getSupabaseClient();
    if (!client) {
        return { success: false, error: 'Supabase не инициализирован' };
    }
    
    try {
        const { error } = await client
            .from(TABLES.PORTFOLIO)
            .delete()
            .eq('id', id);
        
        if (error) {
            console.error('Ошибка удаления работы:', error);
            return { success: false, error: error.message };
        }
        
        return { success: true };
    } catch (error) {
        console.error('Исключение при удалении работы:', error);
        return { success: false, error: error.message };
    }
}

// ============================================
// ФУНКЦИИ ДЛЯ РАБОТЫ С ОТЗЫВАМИ
// ============================================

/**
 * Получает все опубликованные отзывы
 * @returns {Promise<Array>} Массив отзывов
 */
export async function getReviews() {
    const client = getSupabaseClient();
    if (!client) {
        console.warn('Supabase не инициализирован, возвращаем пустой массив');
        return [];
    }
    
    try {
        const { data, error } = await client
            .from(TABLES.REVIEWS)
            .select('*')
            .eq('is_published', true)
            .order('order_index', { ascending: true });
        
        if (error) {
            console.error('Ошибка загрузки отзывов:', error);
            return [];
        }
        
        return data || [];
    } catch (error) {
        console.error('Исключение при загрузке отзывов:', error);
        return [];
    }
}

// ============================================
// ФУНКЦИИ ДЛЯ РАБОТЫ С ПРОЕКТАМИ
// ============================================

/**
 * Получает все опубликованные проекты
 * @returns {Promise<Array>} Массив проектов
 */
export async function getProjects() {
    const client = getSupabaseClient();
    if (!client) {
        console.warn('Supabase не инициализирован, возвращаем пустой массив');
        return [];
    }
    
    try {
        const { data, error } = await client
            .from(TABLES.PROJECTS)
            .select('*')
            .eq('is_published', true)
            .order('order_index', { ascending: true });
        
        if (error) {
            console.error('Ошибка загрузки проектов:', error);
            return [];
        }
        
        return data || [];
    } catch (error) {
        console.error('Исключение при загрузке проектов:', error);
        return [];
    }
}

/**
 * Получает проект по slug
 * @param {string} slug - Slug проекта
 * @returns {Promise<Object|null>} Данные проекта или null
 */
export async function getProjectBySlug(slug) {
    const client = getSupabaseClient();
    if (!client) {
        return null;
    }
    
    try {
        const { data, error } = await client
            .from(TABLES.PROJECTS)
            .select('*')
            .eq('slug', slug)
            .eq('is_published', true)
            .single();
        
        if (error) {
            console.error('Ошибка загрузки проекта:', error);
            return null;
        }
        
        return data;
    } catch (error) {
        console.error('Исключение при загрузке проекта:', error);
        return null;
    }
}

/**
 * Получает проект по ID
 * @param {string} projectId - ID проекта
 * @returns {Promise<Object|null>} Данные проекта или null
 */
export async function getProjectById(projectId) {
    const client = getSupabaseClient();
    if (!client) {
        return null;
    }
    
    try {
        const { data, error } = await client
            .from(TABLES.PROJECTS)
            .select('*')
            .eq('id', projectId)
            .eq('is_published', true)
            .single();
        
        if (error) {
            console.error('Ошибка загрузки проекта:', error);
            return null;
        }
        
        return data;
    } catch (error) {
        console.error('Исключение при загрузке проекта:', error);
        return null;
    }
}

/**
 * Получает видео для проекта
 * @param {string} projectId - ID проекта
 * @param {string} category - Категория видео (опционально)
 * @returns {Promise<Array>} Массив видео
 */
export async function getProjectVideos(projectId, category = null) {
    const client = getSupabaseClient();
    if (!client) {
        return [];
    }
    
    try {
        let query = client
            .from('project_videos')
            .select('*')
            .eq('project_id', projectId)
            .order('order_index', { ascending: true });
        
        if (category) {
            query = query.eq('category', category);
        }
        
        const { data, error } = await query;
        
        if (error) {
            console.error('Ошибка загрузки видео проекта:', error);
            return [];
        }
        
        return data || [];
    } catch (error) {
        console.error('Исключение при загрузке видео проекта:', error);
        return [];
    }
}

/**
 * Получает список файлов из бакета Storage и заполняет таблицу portfolio
 * @param {string} bucketName - Имя бакета (по умолчанию 'portfolio')
 * @returns {Promise<Object>} Результат операции с статистикой
 */
export async function fillPortfolioFromStorage(bucketName = 'portfolio') {
    const client = getSupabaseClient();
    if (!client) {
        return { success: false, error: 'Supabase клиент не инициализирован' };
    }

    const categoryMapping = {
        'ohvatnye': 'ohvatnye',
        'ekspertnye': 'ekspertnye',
        'reklamnye': 'reklamnye',
        'hr': 'hr',
        'sfery': 'sfery'
    };

    let totalCreated = 0;
    let totalUpdated = 0;
    let totalErrors = 0;
    const errors = [];

    try {
        // Получаем список папок (категорий) в бакете
        const { data: folders, error: foldersError } = await client.storage
            .from(bucketName)
            .list('', { limit: 1000, sortBy: { column: 'name', order: 'asc' } });

        if (foldersError) {
            return { success: false, error: `Ошибка получения списка папок: ${foldersError.message}` };
        }

        const categoryFolders = (folders || []).filter(item => 
            !item.name.includes('.') && categoryMapping[item.name.toLowerCase()]
        );

        console.log('Найдено папок категорий:', categoryFolders.map(f => f.name));

        // Обрабатываем каждую категорию
        for (const folder of categoryFolders) {
            const categoryName = folder.name.toLowerCase();
            const mappedCategory = categoryMapping[categoryName];

            // Получаем список файлов в папке категории
            const { data: files, error: filesError } = await client.storage
                .from(bucketName)
                .list(categoryName, { limit: 1000, sortBy: { column: 'name', order: 'asc' } });

            if (filesError) {
                console.error(`Ошибка получения файлов из ${categoryName}:`, filesError);
                continue;
            }

            const videoFiles = (files || []).filter(file => {
                const ext = file.name.toLowerCase().split('.').pop();
                return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv'].includes(ext);
            });

            console.log(`Категория ${categoryName}: найдено ${videoFiles.length} видео файлов`);

            // Создаем или обновляем записи для каждого видео
            for (let i = 0; i < videoFiles.length; i++) {
                const file = videoFiles[i];
                const videoPath = `${categoryName}/${file.name}`;
                
                // Формируем название из имени файла
                const title = file.name
                    .replace(/\.[^/.]+$/, '')
                    .replace(/[-_]/g, ' ')
                    .replace(/\b\w/g, l => l.toUpperCase());

                try {
                    // Проверяем, существует ли уже запись с таким video_url
                    const { data: existing } = await client
                        .from(TABLES.PORTFOLIO)
                        .select('id')
                        .eq('video_url', videoPath)
                        .maybeSingle();

                    if (existing) {
                        // Обновляем существующую запись
                        const { error: updateError } = await client
                            .from(TABLES.PORTFOLIO)
                            .update({
                                title: title,
                                category: mappedCategory,
                                order_index: i,
                                is_published: true
                            })
                            .eq('id', existing.id);

                        if (updateError) {
                            errors.push(`Ошибка обновления ${videoPath}: ${updateError.message}`);
                            totalErrors++;
                        } else {
                            totalUpdated++;
                        }
                    } else {
                        // Создаем новую запись
                        const imageUrl = 'figma-assets/placeholder.png'; // Заглушка

                        const { error: insertError } = await client
                            .from(TABLES.PORTFOLIO)
                            .insert({
                                title: title,
                                description: `Видео ролик из категории ${categoryName}`,
                                video_url: videoPath,
                                image_url: imageUrl,
                                category: mappedCategory,
                                width: 238,
                                height: 368,
                                format: '9-16',
                                order_index: i,
                                is_published: true
                            });

                        if (insertError) {
                            errors.push(`Ошибка создания ${videoPath}: ${insertError.message}`);
                            totalErrors++;
                        } else {
                            totalCreated++;
                        }
                    }
                } catch (error) {
                    errors.push(`Ошибка при обработке ${videoPath}: ${error.message}`);
                    totalErrors++;
                }
            }
        }

        return {
            success: true,
            created: totalCreated,
            updated: totalUpdated,
            errors: totalErrors,
            errorList: errors
        };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

// Автоматическая инициализация при импорте модуля
if (typeof window !== 'undefined') {
    // Инициализируем только в браузере
    initSupabase();
    
    // Экспортируем функцию для использования в консоли
    window.fillPortfolioFromStorage = fillPortfolioFromStorage;
}
