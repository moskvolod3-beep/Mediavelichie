/**
 * Portfolio page functionality
 * Implements masonry layout with category filtering
 */

// Portfolio works data
// Portfolio works data (fallback если Supabase недоступен)
const portfolioWorksFallback = [
    {
        id: 1,
        image: 'figma-assets/bccc3d4bf07de4fe529b163a853fa1e50300dc33.png',
        category: 'ohvatnye',
        width: 490,
        height: 304,
        format: '16-9'
    },
    {
        id: 2,
        image: 'figma-assets/fc52e88aa9f4e759244c3e6e2131f0bf81da24ef.png',
        category: 'ohvatnye',
        width: 238,
        height: 368,
        format: '9-16'
    },
    {
        id: 3,
        image: 'figma-assets/89f3e5d0538b01e7b2ab421ab220571d466d7d40.png',
        category: 'ekspertnye',
        width: 238,
        height: 368,
        format: '9-16'
    },
    {
        id: 4,
        image: 'figma-assets/c967540e5d810ae3e7dc129273d871bfb781460c.png',
        category: 'reklamnye',
        width: 490,
        height: 304,
        format: '16-9'
    },
    {
        id: 5,
        image: 'figma-assets/f2dc1f3f287ad7a71dcf65f0b03a26e8f4f8c3a7.png',
        category: 'ohvatnye',
        width: 238,
        height: 368,
        format: '9-16'
    },
    {
        id: 6,
        image: 'figma-assets/64c900ce6ed2535e56db1e50ac88a00de14bf4b3.png',
        category: 'hr',
        width: 238,
        height: 368,
        format: '9-16'
    },
    {
        id: 7,
        image: 'figma-assets/90b51286c316c3a7502647f792e8378d9cf9d6d1.png',
        category: 'reklamnye',
        width: 490,
        height: 304,
        format: '16-9'
    },
    {
        id: 8,
        image: 'figma-assets/ec45ec5829b77837dbebbfcc28cd31aaa97cb606.png',
        category: 'sfery',
        width: 490,
        height: 304,
        format: '16-9'
    },
    {
        id: 9,
        image: 'figma-assets/46fb259cf12d268c5351b03daa40173a38ce635b.png',
        category: 'ekspertnye',
        width: 490,
        height: 304,
        format: '16-9'
    },
    {
        id: 10,
        image: 'figma-assets/74723beaddf36faa9a26d08a3607ba6d0a829aa2.png',
        category: 'reklamnye',
        width: 490,
        height: 304,
        format: '16-9'
    },
    {
        id: 11,
        image: 'figma-assets/0c5481834d3bb164e5ea350917624e6b7ff8e807.png',
        category: 'sfery',
        width: 490,
        height: 304,
        format: '16-9'
    }
];

let portfolioWorks = [];
let currentCategory = 'all';

/**
 * Загружает портфолио из Supabase
 */
async function loadPortfolioFromSupabase() {
    try {
        const { getPortfolio } = await import('./supabase-client.js');
        const data = await getPortfolio();
        
        // Преобразуем данные из Supabase в формат, ожидаемый функцией renderPortfolio
        portfolioWorks = data.map(item => {
            // Определяем формат из базы данных или вычисляем из width/height
            let format = item.format;
            if (!format && item.width && item.height) {
                // Если формат не указан, вычисляем из соотношения сторон
                const aspectRatio = item.width / item.height;
                format = aspectRatio > 1 ? '16-9' : '9-16'; // Ширина больше высоты = горизонтальный
            }
            format = format || '9-16'; // По умолчанию вертикальный
            
            const work = {
                id: item.id,
                title: item.title || '',
                description: item.description || '',
                image: item.image_url,
                video: item.video_url || null, // Явно устанавливаем null если нет видео
                category: item.category,
                width: item.width || 238,
                height: item.height || 368,
                format: format, // Используем формат из БД или вычисленный
                projectId: item.project_id
            };
            
            // Логируем элементы с видео для отладки
            if (work.video) {
                console.log('Найдено видео:', {
                    id: work.id,
                    title: work.title,
                    video: work.video,
                    category: work.category
                });
            }
            
            return work;
        });
        
        const videosCount = portfolioWorks.filter(w => w.video).length;
        const formatCounts = {
            '16-9': portfolioWorks.filter(w => w.format === '16-9').length,
            '9-16': portfolioWorks.filter(w => w.format === '9-16').length,
            'other': portfolioWorks.filter(w => w.format !== '16-9' && w.format !== '9-16').length
        };
        console.log(`Загружено ${portfolioWorks.length} работ из Supabase, из них с видео: ${videosCount}`);
        console.log(`Форматы: 16-9 (горизонтальные): ${formatCounts['16-9']}, 9-16 (вертикальные): ${formatCounts['9-16']}, другие: ${formatCounts['other']}`);
        
        // Дополнительная отладка: выводим все элементы с видео
        if (videosCount > 0) {
            console.log('Элементы с видео:', portfolioWorks.filter(w => w.video));
        } else {
            console.warn('⚠️ В базе данных нет записей с video_url!');
            console.warn('Добавьте video_url в таблицу portfolio для отображения видео.');
        }
        return true;
    } catch (error) {
        console.warn('Не удалось загрузить портфолио из Supabase, используем fallback данные:', error);
        portfolioWorks = portfolioWorksFallback;
        return false;
    }
}

/**
 * Настраивает параметры masonry-layout компонента в зависимости от размера экрана
 */
function updateMasonryLayout() {
    const masonry = document.getElementById('portfolioMasonry');
    if (!masonry) return;
    
    const windowWidth = window.innerWidth;
    const isMobile = windowWidth <= 768;
    
    if (isMobile) {
        // Мобильная версия: 1 колонка
        masonry.setAttribute('cols', '1');
        masonry.setAttribute('gap', '30');
        masonry.setAttribute('maxcolwidth', '1000');
    } else if (windowWidth <= 1200) {
        // Планшет: 3 колонки
        masonry.setAttribute('cols', '3');
        masonry.setAttribute('gap', '30');
        masonry.setAttribute('maxcolwidth', '350');
    } else {
        // Десктоп: 4 колонки
        masonry.setAttribute('cols', '4');
        masonry.setAttribute('gap', '30');
        masonry.setAttribute('maxcolwidth', '250');
    }
    
    // Вызываем layout для пересчета позиций
    if (masonry.layout) {
        masonry.layout();
    }
}

/**
 * Инициализирует или обновляет Masonry layout (для обратной совместимости)
 */
function initMasonry() {
    updateMasonryLayout();
}

/**
 * Старая функция layoutMasonry (заменена на initMasonry)
 * Оставлена для обратной совместимости
 */
function layoutMasonry() {
    // Вызываем новую функцию инициализации Masonry
    initMasonry();
}

/**
 * Обновляет высоту контейнера на основе реальной высоты masonry
 */
function updateContainerHeight() {
    const masonry = document.getElementById('portfolioMasonry');
    const gridContainer = document.querySelector('.portfolio-grid-container');
    const gridSection = document.querySelector('.portfolio-grid-section');
    
    if (!masonry || !gridContainer || !gridSection) return;
    
    // Вычисляем реальную высоту masonry с учетом всех элементов
    const items = Array.from(masonry.querySelectorAll('.portfolio-item'));
    if (items.length === 0) {
        // Убираем инлайн-стили высоты, чтобы элементы могли естественно подстраиваться
        if (masonry.style.height) {
            masonry.style.height = '';
        }
        if (gridSection.style.minHeight) {
            gridSection.style.minHeight = '';
        }
        return;
    }
    
    // Используем scrollHeight для получения реальной высоты содержимого
    // Это более надежный способ, чем вычисление через getBoundingClientRect
    requestAnimationFrame(() => {
        // Даем браузеру время на пересчет layout
        setTimeout(() => {
            // Вычисляем максимальную высоту через grid-row
            let maxRow = 0;
            items.forEach(item => {
                const gridRow = item.style.gridRow || window.getComputedStyle(item).gridRow;
                if (gridRow && gridRow.includes('/')) {
                    const match = gridRow.match(/\/(\d+)/);
                    if (match) {
                        const rowEnd = parseInt(match[1]);
                        if (rowEnd > maxRow) {
                            maxRow = rowEnd;
                        }
                    }
                }
            });
            
            // НЕ устанавливаем фиксированную высоту для masonry через инлайн-стили
            // Это вызывает изменение высоты родительского контейнера и смещение секций ниже
            // Позволяем masonry естественно подстраиваться под содержимое
            if (masonry.style.height) {
                masonry.style.height = '';
            }
            
            // Устанавливаем min-height секции на высоту masonry + padding-bottom (100px) + margin-bottom (100px)
            // Это гарантирует, что секция будет достаточно высокой для размещения masonry
            // и секция order-section будет ниже без наложения
            const masonryHeight = masonry.offsetHeight || masonry.scrollHeight;
            const sectionPaddingBottom = 100; // Соответствует padding-bottom в CSS
            const masonryMarginBottom = 100; // Соответствует margin-bottom в CSS
            if (masonryHeight > 0) {
                // Высота секции = позиция masonry (top: 162px) + высота masonry + margin-bottom + padding-bottom
                // Используем getBoundingClientRect для более точного расчета
                const masonryRect = masonry.getBoundingClientRect();
                const sectionRect = gridSection.getBoundingClientRect();
                const masonryRelativeTop = masonryRect.top - sectionRect.top;
                const totalHeight = masonryRelativeTop + masonryHeight + masonryMarginBottom + sectionPaddingBottom;
                gridSection.style.minHeight = `${totalHeight}px`;
            }
        }, 50);
    });
}

/**
 * Resize all grid items (now uses masonry-layout component)
 */
function resizeAllGridItems() {
    updateMasonryLayout();
}

/**
 * Handle image load and recalculate layout
 * УБРАНО: не вызываем пересчет при загрузке каждого изображения,
 * так как layout вызывается после загрузки всех изображений в renderPortfolio
 */
function handleImageLoad(item) {
    // Не вызываем пересчет - layout будет вызван после загрузки всех изображений
}

/**
 * Render portfolio works in masonry layout using CSS Grid
 * Based on CodePen approach: https://codepen.io/andybarefoot/pen/QMeZda
 */
function renderPortfolio(filteredWorks = null) {
    const masonry = document.getElementById('portfolioMasonry');
    if (!masonry) return;

    const works = filteredWorks || portfolioWorks;
    
    // Clear existing content
    masonry.innerHTML = '';

    const containerWidth = 1000;
    const numColumns = 4;
    const gap = 10;
    const columnWidth = (containerWidth - (gap * (numColumns - 1))) / numColumns; // ~245px per column
    
    // Render works
    works.forEach((work) => {
        const workItem = document.createElement('div');
        workItem.className = 'portfolio-item';
        workItem.dataset.category = work.category;
        
        // Элементы будут позиционироваться через CSS Grid
        // Не нужно скрывать, так как Grid сам управляет позиционированием
        
        // Create content wrapper
        const content = document.createElement('div');
        content.className = 'content';
        
        // Сохраняем формат для использования в layout
        workItem.dataset.format = work.format || '9-16';

        const img = document.createElement('img');
        img.src = work.image;
        img.alt = work.title || work.description || `Портфолио работа ${work.id}`;
        img.title = work.title || '';
        img.style.width = '100%';
        img.style.height = '100%';
        img.style.objectFit = 'cover';
        img.style.display = 'block';
        img.style.objectPosition = 'center';
        
        // Сохраняем title и description в data-атрибутах для возможного использования
        if (work.title) {
            workItem.dataset.title = work.title;
        }
        if (work.description) {
            workItem.dataset.description = work.description;
        }
        
        // Для нового masonry-layout компонента не нужно устанавливать фиксированную ширину
        // Компонент сам управляет размерами элементов
        // Устанавливаем только aspect-ratio для правильных пропорций
        const format = work.format || '9-16';
        
        // Убираем фиксированные размеры - компонент сам управляет
        workItem.style.width = '';
        workItem.style.height = '';
        
        content.style.width = '100%';
        content.style.height = 'auto';

        content.appendChild(img);
        workItem.appendChild(content);
        
        // Добавляем play overlay только если есть видео
        if (work.video) {
            const playOverlay = document.createElement('div');
            playOverlay.className = 'portfolio-play-overlay';
            const playIcon = document.createElement('img');
            playIcon.src = 'assets/play.svg';
            playIcon.alt = 'Play';
            playIcon.className = 'portfolio-play-icon';
            playOverlay.appendChild(playIcon);
            workItem.appendChild(playOverlay);
        }
        
        masonry.appendChild(workItem);
        
        // Убеждаемся, что элемент виден сразу после добавления
        workItem.style.opacity = '1';
        workItem.style.visibility = 'visible';
        workItem.style.display = 'block';
        
        // Добавляем обработчик клика для воспроизведения видео из бакета
        if (work.video) {
            workItem.style.cursor = 'pointer';
            workItem.dataset.videoSrc = work.video; // Сохраняем URL видео в data-атрибуте
            workItem.classList.add('has-video'); // Добавляем класс для стилизации
            
            workItem.addEventListener('click', (e) => {
                // Не открываем видео, если клик был на другие элементы
                if (e.target.closest('a, button')) {
                    return;
                }
                
                e.preventDefault();
                e.stopPropagation();
                
                console.log('Клик по видео элементу:', {
                    id: work.id,
                    title: work.title,
                    videoUrl: work.video
                });
                
                // Используем встроенный video player
                if (typeof window.openVideoPlayer === 'function') {
                    window.openVideoPlayer(work.video);
                } else {
                    console.warn('Video player не доступен, используем fallback');
                    // Fallback: открываем в новом окне
                    window.open(work.video, '_blank');
                }
            });
        } else {
            // Если нет видео, убираем курсор pointer
            workItem.style.cursor = 'default';
        }
        
        // Обработка загрузки изображений - layout будет вызван после загрузки всех изображений
        // Не нужно обрабатывать каждое изображение отдельно, так как мы ждем все через Promise.all
    });
    
    // Ждем загрузки всех изображений перед layout (критично для правильных размеров)
    const allImages = Array.from(masonry.querySelectorAll('img'));
    const imagePromises = allImages.map(img => {
        if (img.complete && img.naturalHeight !== 0) {
            return Promise.resolve();
        }
        return new Promise((resolve) => {
            img.addEventListener('load', resolve, { once: true });
            img.addEventListener('error', resolve, { once: true });
        });
    });
    
    // Выполняем layout после загрузки всех изображений
    Promise.all(imagePromises).then(() => {
        // Даем браузеру время на рендеринг изображений
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                // Убеждаемся, что элементы видны
                const items = Array.from(masonry.querySelectorAll('.portfolio-item'));
                items.forEach(item => {
                    item.style.opacity = '1';
                    item.style.visibility = 'visible';
                });
                
                // Обновляем настройки masonry-layout компонента
                updateMasonryLayout();
                
                // Вызываем layout компонента для пересчета позиций
                setTimeout(() => {
                    if (masonry && masonry.layout) {
                        masonry.layout();
                    }
                    // Обновляем высоту секции после layout
                    updateContainerHeight();
                }, 100);
            });
        });
    });
}

/**
 * Filter works by category
 */
function filterPortfolio(category) {
    currentCategory = category;
    
    const filteredWorks = category === 'all' 
        ? portfolioWorks 
        : portfolioWorks.filter(work => work.category === category);

    // Update active filter button
    document.querySelectorAll('.portfolio-filter-btn').forEach(btn => {
        if (btn.dataset.category === category) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });

    // Re-render with filtered works
    renderPortfolio(filteredWorks);
    
    // После фильтрации layoutMasonry будет вызван автоматически из renderPortfolio
    // Обновляем высоту секции после фильтрации
    setTimeout(() => {
        updateContainerHeight();
    }, 600);
}

/**
 * Загружает и устанавливает hero видео из портфолио
 */
async function loadHeroVideo() {
    try {
        const { getPortfolio } = await import('./supabase-client.js');
        const portfolioItems = await getPortfolio('reklamnye'); // Берем из категории рекламные
        
        if (portfolioItems && portfolioItems.length > 0) {
            // Берем первое видео из категории рекламные
            const heroVideo = portfolioItems[0];
            const videoPlayer = document.getElementById('portfolioHeroBgVideo');
            
            if (videoPlayer && heroVideo.video_url && heroVideo.image_url) {
                // Обновляем постер
                videoPlayer.poster = heroVideo.image_url;
                
                // Обновляем source
                let source = videoPlayer.querySelector('source');
                if (!source) {
                    source = document.createElement('source');
                    videoPlayer.appendChild(source);
                }
                source.src = heroVideo.video_url;
                source.type = 'video/mp4';
                
                // Перезагружаем видео
                videoPlayer.load();
            }
        }
    } catch (error) {
        console.warn('Не удалось загрузить hero видео из базы:', error);
    }
}

/**
 * Initialize portfolio page
 */
async function initPortfolio() {
    // Загружаем hero видео из базы данных
    await loadHeroVideo();
    
    // Загружаем данные из Supabase
    await loadPortfolioFromSupabase();
    
    // Set up filter buttons
    document.querySelectorAll('.portfolio-filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const category = btn.dataset.category;
            filterPortfolio(category);
        });
    });

    // Initial render
    renderPortfolio();
    
    // Настраиваем masonry-layout после начального рендера
    setTimeout(() => {
        updateMasonryLayout();
    }, 100);
    
    // Handle hash parameter for filter (e.g., portfolio.html#filter-ohvatnye)
    const handleHashFilter = () => {
        const hash = window.location.hash;
        if (hash && hash.startsWith('#filter-')) {
            const category = hash.replace('#filter-', '');
            // Validate category exists
            const validCategories = ['ohvatnye', 'ekspertnye', 'reklamnye', 'hr', 'all'];
            if (validCategories.includes(category)) {
                // Scroll to portfolio section
                const portfolioSection = document.querySelector('.portfolio-grid-section');
                if (portfolioSection) {
                    portfolioSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
                // Apply filter after a short delay
                setTimeout(() => {
                    filterPortfolio(category);
                }, 300);
            }
        }
    };
    
    // Check hash on page load
    handleHashFilter();
    
    // Listen for hash changes
    window.addEventListener('hashchange', handleHashFilter);
    
    // Recalculate layout on window resize (только при изменении размера окна)
    let resizeTimeout;
    let lastWindowWidth = window.innerWidth;
    window.addEventListener('resize', () => {
        const currentWidth = window.innerWidth;
        // Пересчитываем только если изменилась ширина окна
        if (currentWidth !== lastWindowWidth) {
            lastWindowWidth = currentWidth;
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(() => {
                // Обновляем настройки masonry-layout компонента
                updateMasonryLayout();
            }, 150);
        }
    });
    
    // НЕ используем ResizeObserver - он вызывает постоянные пересчеты при изменении содержимого
    // что создает цикл перестройки и смещение элементов
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initPortfolio);
