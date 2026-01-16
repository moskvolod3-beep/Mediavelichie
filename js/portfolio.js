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
 * Алгоритм размещения элементов в стиле домино
 * Видео 16-9: занимают 2 ячейки по горизонтали, 1 по вертикали
 * Видео 9-16: занимают 1 ячейку по горизонтали, 2 по вертикали
 * Использует состояние строки для отслеживания занятых ячеек
 */
function layoutMasonry() {
    const masonry = document.getElementById('portfolioMasonry');
    if (!masonry) return;
    
    const items = Array.from(masonry.querySelectorAll('.portfolio-item'));
    if (items.length === 0) return;
    
    const numColumns = 4;
    const gap = 10;
    const containerWidth = 1000;
    const columnWidth = (containerWidth - (gap * (numColumns - 1))) / numColumns;
    
    // Состояние следующей строки: 0 = свободно, 1 = занято вертикальным блоком
    let state = [0, 0, 0, 0];
    let currentRow = 1;
    
    // Высота одной строки в Grid (без учета gap)
    // Вертикальный элемент (9-16): занимает 2 строки
    // Реальная высота элемента = 2 * rowHeight + gap (gap между строками)
    // Для соотношения 1x2: высота = 2 * ширина
    // Значит: 2 * rowHeight + gap = 2 * columnWidth
    // Отсюда: rowHeight = (2 * columnWidth - gap) / 2 = columnWidth - gap/2
    const rowHeight = columnWidth - gap / 2;
    
    // Функция для размещения блока
    const placeBlock = (item, col, row, w, h, format) => {
        // Устанавливаем grid позицию (Grid использует 1-based индексацию)
        item.style.gridColumn = `${col} / span ${w}`;
        item.style.gridRow = `${row} / span ${h}`;
        
        // Устанавливаем размеры на основе формата согласно правилу:
        // 9-16 → соотношение 1x2 (высота = 2 * ширина)
        // 16-9 → соотношение 2x1 (ширина = 2 * высота)
        if (format === '16-9') {
            // Горизонтальное: 2 колонки шириной, соотношение 2x1, занимает 1 строку
            // Ширина = 2 колонки + gap между ними
            const width = columnWidth * 2 + gap;
            // Высота должна соответствовать соотношению 2x1: высота = ширина / 2
            // Высота = высота одной строки (без gap, так как gap уже учтен в Grid)
            const height = rowHeight;
            item.style.width = `${width}px`;
            item.style.height = `${height}px`;
            item.style.maxWidth = `${width}px`;
            item.style.maxHeight = `${height}px`;
        } else {
            // Вертикальное: 1 колонка шириной, соотношение 1x2, занимает 2 строки
            // Ширина = 1 колонка
            const width = columnWidth;
            // Высота = 2 строки + gap между ними для точного выравнивания с сеткой
            // Реальная высота элемента = 2 * rowHeight + gap
            // Но для соблюдения соотношения 1x2: высота = 2 * ширина
            // Проверяем: если разница больше определенного значения, корректируем
            const calculatedHeight = width * 2; // Соотношение 1x2
            const gridHeight = rowHeight * 2 + gap; // Высота по сетке (2 строки + gap)
            const heightDiff = Math.abs(calculatedHeight - gridHeight);
            
            // Если разница больше 5px, используем расчетную высоту для соблюдения пропорций
            // Иначе используем высоту по сетке для точного выравнивания
            const height = heightDiff > 5 ? calculatedHeight : gridHeight;
            
            item.style.width = `${width}px`;
            item.style.height = `${height}px`;
            item.style.maxWidth = `${width}px`;
            item.style.maxHeight = `${height}px`;
        }
    };
    
    // Размещаем элементы построчно
    let itemIndex = 0;
    let maxIterations = items.length * 10; // Защита от бесконечного цикла
    let iterations = 0;
    let skippedItems = []; // Элементы, которые не удалось разместить
    
    while (itemIndex < items.length && iterations < maxIterations) {
        iterations++;
        const nextState = [0, 0, 0, 0];
        let c = 0;
        let hasPlacedInRow = false;
        const startItemIndex = itemIndex; // Запоминаем начальный индекс для проверки прогресса
        
        // Размещаем элементы в текущей строке
        while (c < numColumns && itemIndex < items.length) {
            // Если ячейка занята вертикальным блоком из предыдущей строки, пропускаем
            if (state[c] === 1) {
                c++;
                continue;
            }
            
            const item = items[itemIndex];
            if (!item) {
                itemIndex++;
                continue;
            }
            
            const format = item.dataset.format || '9-16';
            
            // Пробуем разместить горизонтальный блок (16-9)
            if (format === '16-9') {
                // Проверяем, есть ли место для горизонтального блока (2 ячейки)
                if (c + 1 < numColumns && state[c + 1] === 0) {
                    placeBlock(item, c + 1, currentRow, 2, 1, format);
                    c += 2;
                    itemIndex++;
                    hasPlacedInRow = true;
                } else {
                    // Горизонтальный блок не помещается в текущей позиции
                    // Пробуем найти другое место в этой строке
                    let found = false;
                    for (let tryCol = c + 1; tryCol < numColumns - 1; tryCol++) {
                        if (state[tryCol] === 0 && state[tryCol + 1] === 0) {
                            placeBlock(item, tryCol + 1, currentRow, 2, 1, format);
                            c = tryCol + 2;
                            itemIndex++;
                            hasPlacedInRow = true;
                            found = true;
                            break;
                        }
                    }
                    // Если не нашли место в этой строке, пропускаем этот элемент
                    if (!found) {
                        skippedItems.push({ item, index: itemIndex, format });
                        itemIndex++;
                    }
                }
            } 
            // Размещаем вертикальный блок (9-16)
            else if (format === '9-16') {
                placeBlock(item, c + 1, currentRow, 1, 2, format);
                nextState[c] = 1; // Помечаем ячейку как занятую в следующей строке
                c += 1;
                itemIndex++;
                hasPlacedInRow = true;
            }
            // Неизвестный формат - пропускаем
            else {
                console.warn(`Неизвестный формат: ${format}, пропускаем элемент ${itemIndex}`);
                skippedItems.push({ item, index: itemIndex, format });
                itemIndex++;
            }
        }
        
        // Если в строке ничего не разместили, но есть еще элементы - переходим к следующей строке
        // Это предотвращает бесконечный цикл
        if (!hasPlacedInRow && itemIndex < items.length) {
            // Пропускаем текущую строку и переходим к следующей
            state = [0, 0, 0, 0]; // Сбрасываем состояние, так как ничего не разместили
            currentRow++;
        } else {
            // Переходим к следующей строке
            state = nextState;
            currentRow++;
        }
        
        // Если не было прогресса (не разместили ни одного элемента), выходим
        if (itemIndex === startItemIndex && itemIndex < items.length) {
            console.warn('Не удалось разместить элементы, возможна ошибка в данных');
            break;
        }
    }
    
    // Пытаемся разместить пропущенные элементы в конце
    if (skippedItems.length > 0) {
        console.log(`Пытаемся разместить ${skippedItems.length} пропущенных элементов`);
        skippedItems.forEach(({ item, format }) => {
            // Ищем свободное место в сетке для пропущенных элементов
            let placed = false;
            let tryRow = currentRow;
            let maxTryRows = 20; // Максимум попыток
            
            while (!placed && tryRow < currentRow + maxTryRows) {
                // Для вертикальных элементов ищем свободную колонку
                if (format === '9-16') {
                    for (let col = 0; col < numColumns; col++) {
                        // Проверяем, свободна ли колонка в этой и следующей строке
                        const canPlace = !state[col] || state[col] === 0;
                        if (canPlace) {
                            placeBlock(item, col + 1, tryRow, 1, 2, format);
                            placed = true;
                            break;
                        }
                    }
                } 
                // Для горизонтальных элементов ищем пару свободных колонок
                else if (format === '16-9') {
                    for (let col = 0; col < numColumns - 1; col++) {
                        // Проверяем, свободны ли две соседние колонки
                        const canPlace = (!state[col] || state[col] === 0) && 
                                        (!state[col + 1] || state[col + 1] === 0);
                        if (canPlace) {
                            placeBlock(item, col + 1, tryRow, 2, 1, format);
                            placed = true;
                            break;
                        }
                    }
                }
                
                if (!placed) {
                    tryRow++;
                    state = [0, 0, 0, 0]; // Сбрасываем состояние для новой строки
                }
            }
            
            if (!placed) {
                console.warn(`Не удалось разместить элемент с форматом ${format}`);
            }
        });
    }
    
    if (iterations >= maxIterations) {
        console.error('Достигнуто максимальное количество итераций, возможен бесконечный цикл');
    }
    
    // Обновляем высоту контейнера после размещения элементов
    updateContainerHeight();
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
        masonry.style.height = 'auto';
        gridSection.style.minHeight = 'auto';
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
            
            // Если не удалось получить через grid-row, используем getBoundingClientRect
            if (maxRow === 0) {
                let maxBottom = 0;
                items.forEach(item => {
                    const rect = item.getBoundingClientRect();
                    const masonryRect = masonry.getBoundingClientRect();
                    const relativeBottom = rect.bottom - masonryRect.top;
                    if (relativeBottom > maxBottom) {
                        maxBottom = relativeBottom;
                    }
                });
                
                if (maxBottom > 0) {
                    masonry.style.height = `${maxBottom + 50}px`; // 50px - margin-bottom
                }
            } else {
                // Высота одной строки grid = 242.5px, gap = 10px
                // Высота = (maxRow - 1) * 242.5 + дополнительные отступы
                const rowHeight = 242.5;
                const gap = 10;
                const calculatedHeight = (maxRow - 1) * rowHeight + gap * (maxRow - 1) + rowHeight;
                masonry.style.height = `${calculatedHeight + 50}px`; // +50px для margin-bottom
            }
            
            // Обновляем высоту секции
            const masonryHeight = masonry.offsetHeight;
            const filtersHeight = document.querySelector('.portfolio-filters')?.offsetHeight || 0;
            const filtersTop = 67; // top: 67px
            const filtersMarginBottom = 30; // margin-bottom фильтров
            const masonryTop = 198; // top: 198px
            const sectionPaddingBottom = 150; // padding-bottom секции
            
            const totalHeight = filtersTop + filtersHeight + filtersMarginBottom + masonryTop + masonryHeight + sectionPaddingBottom;
            gridSection.style.minHeight = `${totalHeight}px`;
        }, 50);
    });
}

// Debounce для layoutMasonry чтобы избежать множественных пересчетов
let layoutMasonryTimeout = null;
let isLayouting = false;

/**
 * Debounced version of layoutMasonry
 */
function debouncedLayoutMasonry() {
    if (isLayouting) return;
    
    if (layoutMasonryTimeout) {
        clearTimeout(layoutMasonryTimeout);
    }
    
    layoutMasonryTimeout = setTimeout(() => {
        isLayouting = true;
        requestAnimationFrame(() => {
            layoutMasonry();
            isLayouting = false;
        });
    }, 50);
}

/**
 * Resize all grid items (now uses column-based layout)
 */
function resizeAllGridItems() {
    debouncedLayoutMasonry();
}

/**
 * Handle image load and recalculate layout
 */
function handleImageLoad(item) {
    debouncedLayoutMasonry();
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
        // В матричном подходе мы не устанавливаем columnSpan здесь,
        // а используем format для определения размера в layoutMasonry
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
        
        // Для матричного Grid подхода не устанавливаем фиксированные размеры
        // Grid сам управляет размерами элементов на основе grid-column и grid-row
        content.style.width = '100%';
        content.style.height = '100%';

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
        // Используем несколько requestAnimationFrame для гарантии полного рендеринга
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    layoutMasonry();
                    // Обновляем высоту после layout
                    setTimeout(() => {
                        updateContainerHeight();
                    }, 100);
                });
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
    
    // Обновляем высоту после фильтрации
    setTimeout(() => {
        updateContainerHeight();
    }, 500);
}

/**
 * Initialize portfolio page
 */
async function initPortfolio() {
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
    
    // Recalculate layout on window resize
    let resizeTimeout;
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(() => {
            debouncedLayoutMasonry();
        }, 150);
    });
    
    // Используем ResizeObserver для отслеживания изменений размера контейнера masonry
    if (typeof ResizeObserver !== 'undefined') {
        const masonry = document.getElementById('portfolioMasonry');
        if (masonry) {
            const resizeObserver = new ResizeObserver(() => {
                debouncedLayoutMasonry();
            });
            resizeObserver.observe(masonry);
        }
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initPortfolio);
