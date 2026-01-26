/**
 * Reviews Loader
 * Загружает отзывы из Supabase и отображает их на странице
 */

import { getReviews } from './supabase-client.js';

/**
 * Форматирует дату для отображения
 */
function formatDate(dateString) {
    const date = new Date(dateString);
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    const day = date.getDate();
    const month = months[date.getMonth()];
    return `${day} ${month}`;
}

/**
 * Создает HTML элемент отзыва
 */
function createReviewCard(review) {
    const card = document.createElement('div');
    card.className = 'review-card-3d';
    
    const date = review.created_at ? formatDate(review.created_at) : '';
    const avatarUrl = review.author_avatar_url || 'assets/Ellipse 73.svg';
    
    // Создаем звезды рейтинга
    const starsHtml = Array(review.rating || 5)
        .fill(0)
        .map(() => '<span>★</span>')
        .join('');
    
    card.innerHTML = `
        <div class="review-content">
            <img src="${avatarUrl}" alt="Avatar" class="review-avatar">
            <div class="review-header">
                <h3 class="review-author">${review.author_name || 'Аноним'}</h3>
                ${date ? `<span class="review-date">${date}</span>` : ''}
                <div class="review-rating">
                    ${starsHtml}
                </div>
            </div>
            <div class="review-text">
                <p>${review.text || ''}</p>
            </div>
        </div>
    `;
    
    return card;
}

/**
 * Загружает и отображает отзывы
 */
export async function loadReviews() {
    const carouselRoot = document.querySelector('.reviews-3d-container .carousel-root');
    if (!carouselRoot) {
        console.warn('Контейнер отзывов не найден');
        return;
    }
    
    try {
        const reviews = await getReviews();
        
        if (reviews.length === 0) {
            console.warn('Отзывы не найдены');
            return;
        }
        
        // Очищаем существующие отзывы (если есть)
        carouselRoot.innerHTML = '';
        
        // Создаем карточки отзывов
        reviews.forEach(review => {
            const card = createReviewCard(review);
            carouselRoot.appendChild(card);
        });
        
        // Если используется карусель, нужно переинициализировать её
        if (typeof Carousel3D !== 'undefined') {
            const container = document.querySelector('.reviews-3d-container');
            if (container) {
                // Удаляем старый экземпляр карусели, если есть
                if (window.reviewsCarousel) {
                    // Можно добавить метод destroy, если он есть
                }
                
                // Создаем новый экземпляр карусели
                window.reviewsCarousel = new Carousel3D(container, {
                    radius: 400,
                    cardWidth: 324
                });
                
                // Обновляем обработчики навигации
                const prevBtn = document.querySelector('.reviews-prev');
                const nextBtn = document.querySelector('.reviews-next');
                
                if (prevBtn) {
                    prevBtn.replaceWith(prevBtn.cloneNode(true));
                    document.querySelector('.reviews-prev').addEventListener('click', () => {
                        window.reviewsCarousel.prev();
                    });
                }
                
                if (nextBtn) {
                    nextBtn.replaceWith(nextBtn.cloneNode(true));
                    document.querySelector('.reviews-next').addEventListener('click', () => {
                        window.reviewsCarousel.next();
                    });
                }
            }
        }
        
        console.log(`Загружено ${reviews.length} отзывов`);
    } catch (error) {
        console.error('Ошибка загрузки отзывов:', error);
    }
}

// Автоматическая загрузка при инициализации модуля (если DOM готов)
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadReviews);
} else {
    loadReviews();
}
