// Основной скрипт для главной страницы
document.addEventListener('DOMContentLoaded', () => {
    // Навигация с направлений на портфолио с фильтром
    initDirectionOverlayNavigation();
    
    // Открытие видеоплеера при клике на элементы портфолио
    initPortfolioVideoPlayer();
});

/**
 * Инициализация навигации с оверлеев направлений на портфолио с фильтром
 */
function initDirectionOverlayNavigation() {
    const directionCards = document.querySelectorAll('.direction-card');
    
    // Маппинг названий направлений на категории фильтров
    const directionToFilterMap = {
        'Охватные': 'ohvatnye',
        'Экспертные': 'ekspertnye',
        'Рекламные': 'reklamnye'
    };
    
    directionCards.forEach(card => {
        const overlay = card.querySelector('.direction-overlay');
        const directionName = card.querySelector('.direction-name');
        
        if (overlay && directionName) {
            const directionText = directionName.textContent.trim();
            const filterCategory = directionToFilterMap[directionText];
            
            if (filterCategory) {
                // Делаем оверлей кликабельным
                overlay.style.cursor = 'pointer';
                
                // Добавляем обработчик клика
                overlay.addEventListener('click', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    
                    // Переход на страницу портфолио с фильтром
                    window.location.href = `portfolio.html#filter-${filterCategory}`;
                });
            }
        }
    });
}

/**
 * Инициализация открытия видеоплеера при клике на элементы портфолио
 */
function initPortfolioVideoPlayer() {
    // Ждем, пока видеоплеер будет инициализирован
    const checkVideoPlayer = () => {
        if (typeof window.openVideoPlayer === 'function') {
            attachPortfolioClickHandlers();
        } else {
            // Повторяем проверку через небольшой интервал
            setTimeout(checkVideoPlayer, 100);
        }
    };
    
    checkVideoPlayer();
}

/**
 * Прикрепление обработчиков кликов на элементы портфолио
 */
function attachPortfolioClickHandlers() {
    const portfolioItems = document.querySelectorAll('.portfolio-section .portfolio-item');
    
    portfolioItems.forEach(item => {
        // Пропускаем элементы, которые уже имеют обработчики из video-player.js
        // (они будут работать автоматически, если data-video-src заполнен)
        
        // Делаем элемент кликабельным
        item.style.cursor = 'pointer';
        
        // Обработчик клика на весь элемент или изображение
        const handleClick = (e) => {
            // Не открываем плеер, если клик по ссылке или кнопке внутри
            if (e.target.closest('a, button')) {
                return;
            }
            
            e.preventDefault();
            e.stopPropagation();
            
            // Получаем источник видео из data-video-src атрибута
            const videoSrc = item.dataset.videoSrc;
            
            if (videoSrc && videoSrc.trim() !== '') {
                // Открываем видеоплеер с указанным видео
                window.openVideoPlayer(videoSrc);
            } else {
                // Если видео не указано, используем плейсхолдер для демонстрации
                // В продакшене здесь должен быть реальный URL видео
                const placeholderVideo = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
                window.openVideoPlayer(placeholderVideo);
            }
        };
        
        // Добавляем обработчик на элемент
        // Используем capture phase, чтобы наш обработчик сработал первым
        item.addEventListener('click', handleClick, true);
        
        const img = item.querySelector('.portfolio-img');
        if (img) {
            img.style.cursor = 'pointer';
        }
    });
}
