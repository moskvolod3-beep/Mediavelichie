/**
 * Скрипт для заполнения таблицы portfolio на основе файлов в бакете Storage
 * 
 * Использование:
 * 1. Откройте консоль браузера на странице portfolio.html
 * 2. Выполните: import('./js/fill-portfolio-from-storage.js').then(m => m.fillPortfolioFromStorage())
 */

import { getSupabaseClient } from './supabase-client.js';
import { SUPABASE_CONFIG } from '../supabase/config.js';

/**
 * Получает список файлов из бакета Storage
 */
async function listFilesInBucket(bucketName = 'portfolio') {
    const client = getSupabaseClient();
    if (!client) {
        console.error('Supabase клиент не инициализирован');
        return [];
    }

    try {
        const { data, error } = await client.storage.from(bucketName).list('', {
            limit: 1000,
            offset: 0,
            sortBy: { column: 'name', order: 'asc' }
        });

        if (error) {
            console.error('Ошибка получения списка файлов:', error);
            return [];
        }

        return data || [];
    } catch (error) {
        console.error('Исключение при получении списка файлов:', error);
        return [];
    }
}

/**
 * Получает список файлов из папки категории
 */
async function listFilesInCategory(bucketName, categoryPath) {
    const client = getSupabaseClient();
    if (!client) {
        return [];
    }

    try {
        const { data, error } = await client.storage.from(bucketName).list(categoryPath, {
            limit: 1000,
            offset: 0,
            sortBy: { column: 'name', order: 'asc' }
        });

        if (error) {
            console.error(`Ошибка получения файлов из ${categoryPath}:`, error);
            return [];
        }

        return data || [];
    } catch (error) {
        console.error(`Исключение при получении файлов из ${categoryPath}:`, error);
        return [];
    }
}

/**
 * Маппинг категорий из папок в значения базы данных
 */
const categoryMapping = {
    'ohvatnye': 'ohvatnye',
    'ekspertnye': 'ekspertnye',
    'reklamnye': 'reklamnye',
    'hr': 'hr',
    'sfery': 'sfery'
};

/**
 * Заполняет таблицу portfolio на основе файлов в бакете
 */
export async function fillPortfolioFromStorage() {
    console.log('Начинаем заполнение таблицы portfolio из бакета...');
    
    const client = getSupabaseClient();
    if (!client) {
        console.error('Supabase клиент не инициализирован');
        return;
    }

    const bucketName = 'portfolio';
    
    // Получаем список папок (категорий) в бакете
    const folders = await listFilesInBucket(bucketName);
    const categoryFolders = folders.filter(item => !item.name.includes('.')); // Папки обычно не имеют расширения
    
    console.log('Найдено папок категорий:', categoryFolders.map(f => f.name));

    let totalCreated = 0;
    let totalUpdated = 0;
    let totalErrors = 0;

    // Обрабатываем каждую категорию
    for (const folder of categoryFolders) {
        const categoryName = folder.name.toLowerCase();
        const mappedCategory = categoryMapping[categoryName];
        
        if (!mappedCategory) {
            console.warn(`Неизвестная категория: ${categoryName}, пропускаем`);
            continue;
        }

        console.log(`\nОбрабатываем категорию: ${categoryName} (${mappedCategory})`);

        // Получаем список файлов в папке категории
        const files = await listFilesInCategory(bucketName, categoryName);
        const videoFiles = files.filter(file => {
            const ext = file.name.toLowerCase().split('.').pop();
            return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv'].includes(ext);
        });

        console.log(`Найдено видео файлов: ${videoFiles.length}`);

        // Создаем или обновляем записи для каждого видео
        for (let i = 0; i < videoFiles.length; i++) {
            const file = videoFiles[i];
            const videoPath = `${categoryName}/${file.name}`;
            
            // Формируем название из имени файла
            const title = file.name
                .replace(/\.[^/.]+$/, '') // Убираем расширение
                .replace(/[-_]/g, ' ') // Заменяем дефисы и подчеркивания на пробелы
                .replace(/\b\w/g, l => l.toUpperCase()); // Первая буква каждого слова заглавная

            try {
                // Проверяем, существует ли уже запись с таким video_url
                const { data: existing } = await client
                    .from('portfolio')
                    .select('id')
                    .eq('video_url', videoPath)
                    .maybeSingle();

                if (existing) {
                    // Обновляем существующую запись
                    const { error: updateError } = await client
                        .from('portfolio')
                        .update({
                            title: title,
                            category: mappedCategory,
                            order_index: i,
                            is_published: true
                        })
                        .eq('id', existing.id);

                    if (updateError) {
                        console.error(`Ошибка обновления записи для ${videoPath}:`, updateError);
                        totalErrors++;
                    } else {
                        console.log(`✓ Обновлено: ${title}`);
                        totalUpdated++;
                    }
                } else {
                    // Создаем новую запись
                    // Нужно получить image_url - можно использовать первое изображение из той же папки или заглушку
                    const imageFiles = files.filter(f => {
                        const ext = f.name.toLowerCase().split('.').pop();
                        return ['jpg', 'jpeg', 'png', 'webp'].includes(ext);
                    });
                    
                    const imageUrl = imageFiles.length > 0 
                        ? `figma-assets/${imageFiles[0].name}` // Используем локальное изображение как fallback
                        : 'figma-assets/placeholder.png'; // Заглушка

                    const { error: insertError } = await client
                        .from('portfolio')
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
                        console.error(`Ошибка создания записи для ${videoPath}:`, insertError);
                        totalErrors++;
                    } else {
                        console.log(`✓ Создано: ${title}`);
                        totalCreated++;
                    }
                }
            } catch (error) {
                console.error(`Ошибка при обработке ${videoPath}:`, error);
                totalErrors++;
            }
        }
    }

    console.log(`\n=== Результаты ===`);
    console.log(`Создано записей: ${totalCreated}`);
    console.log(`Обновлено записей: ${totalUpdated}`);
    console.log(`Ошибок: ${totalErrors}`);
    console.log(`\nГотово! Обновите страницу портфолио для просмотра результатов.`);
}

// Экспортируем для использования в консоли
if (typeof window !== 'undefined') {
    window.fillPortfolioFromStorage = fillPortfolioFromStorage;
}
