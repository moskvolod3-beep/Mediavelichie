/**
 * Админ-панель для загрузки видео в портфолио
 */

// Состояние приложения
let state = {
    videoFile: null,
    compressedVideoPath: null,
    frames: [],
    selectedFrame: null,
    selectedCategory: null,
    videoId: null
};

// Флаг для предотвращения случайной перезагрузки
let isProcessing = false;
let processingStartTime = null;
const PROCESSING_TIMEOUT = 600000; // 10 минут - максимальное время обработки

// Предотвращаем перезагрузку страницы при обработке
window.addEventListener('beforeunload', (e) => {
    // Проверяем, действительно ли идет обработка (не застрял ли флаг)
    if (isProcessing) {
        // Если обработка идет слишком долго, возможно флаг застрял - сбрасываем
        if (processingStartTime && (Date.now() - processingStartTime) > PROCESSING_TIMEOUT) {
            console.warn('Обнаружен застрявший флаг isProcessing, сбрасываем');
            isProcessing = false;
            processingStartTime = null;
            return;
        }
        
        // Проверяем, действительно ли есть активная обработка (видимые индикаторы)
        const processingVisible = processingSection && processingSection.style.display !== 'none';
        const loaderVisible = (submitLoader && submitLoader.style.display !== 'none') || 
                             (document.getElementById('saveLoader') && document.getElementById('saveLoader').style.display !== 'none');
        
        if (processingVisible || loaderVisible) {
            e.preventDefault();
            e.returnValue = 'Идет обработка видео. Вы уверены, что хотите покинуть страницу?';
            return e.returnValue;
        } else {
            // Если индикаторы не видны, но флаг установлен - сбрасываем флаг
            console.warn('Флаг isProcessing установлен, но индикаторы обработки не видны. Сбрасываем флаг.');
            isProcessing = false;
            processingStartTime = null;
        }
    }
});

// Элементы DOM (инициализируются после загрузки DOM)
let uploadArea, fileInput, uploadForm, submitBtn, submitText, submitLoader;
let fileName, processingSection, progressFill, progressText, errorSection, errorMessage;

function initDOMElements() {
    uploadArea = document.getElementById('uploadArea');
    fileInput = document.getElementById('fileInput');
    uploadForm = document.getElementById('uploadForm');
    submitBtn = document.getElementById('submitBtn');
    submitText = document.getElementById('submitText');
    submitLoader = document.getElementById('submitLoader');
    fileName = document.getElementById('fileName');
    processingSection = document.getElementById('processingSection');
    progressFill = document.getElementById('progressFill');
    progressText = document.getElementById('progressText');
    errorSection = document.getElementById('errorSection');
    errorMessage = document.getElementById('errorMessage');
    
    if (!uploadForm) {
        console.error('Форма uploadForm не найдена!');
        return false;
    }
    return true;
}

// Шаги
const steps = {
    upload: { element: document.getElementById('step1'), tab: document.getElementById('uploadTab') },
    category: { element: document.getElementById('step2'), tab: document.getElementById('categoryTab') },
    frames: { element: document.getElementById('step3'), tab: document.getElementById('framesTab') },
    metadata: { element: document.getElementById('step4'), tab: document.getElementById('metadataTab') }
};

// Инициализация обработчиков событий
function initEventHandlers() {
    if (!uploadArea || !fileInput || !uploadForm) {
        console.error('Не все элементы DOM найдены!');
        return;
    }
    
    // Обработка перетаскивания файла
    uploadArea.addEventListener('dragover', (e) => {
        e.preventDefault();
        uploadArea.classList.add('dragover');
    });

    uploadArea.addEventListener('dragleave', () => {
        uploadArea.classList.remove('dragover');
    });

    uploadArea.addEventListener('drop', (e) => {
        e.preventDefault();
        uploadArea.classList.remove('dragover');
        
        const file = e.dataTransfer.files[0];
        if (file && file.type.startsWith('video/')) {
            handleFileSelect(file);
        } else {
            showError('Пожалуйста, выберите видеофайл');
        }
    });

    uploadArea.addEventListener('click', () => {
        fileInput.click();
    });

    fileInput.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (file) {
            handleFileSelect(file);
        }
    });
}

function handleFileSelect(file) {
    state.videoFile = file;
    fileName.textContent = `Выбран файл: ${file.name} (${formatFileSize(file.size)})`;
    fileName.style.display = 'block';
    submitBtn.disabled = false;
    hideError();
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function showError(message) {
    errorMessage.textContent = message;
    errorSection.style.display = 'block';
    processingSection.style.display = 'none';
}

function hideError() {
    errorSection.style.display = 'none';
}

function updateStep(stepName, status = 'active') {
    // Сбрасываем все шаги
    Object.values(steps).forEach(step => {
        step.element.classList.remove('active', 'completed');
        step.tab.style.display = 'none';
    });

    // Устанавливаем текущий шаг
    if (status === 'active') {
        steps[stepName].element.classList.add('active');
        steps[stepName].tab.style.display = 'block';
    } else if (status === 'completed') {
        steps[stepName].element.classList.add('completed');
    }
}

// Обработка отправки формы загрузки
function initFormHandlers() {
    if (!uploadForm) {
        console.error('Форма uploadForm не найдена для инициализации обработчика!');
        return;
    }
    
    uploadForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        
        if (isProcessing) {
            return false;
        }
    
    if (!state.videoFile) {
        showError('Пожалуйста, выберите файл');
        return false;
    }
    
    const formData = new FormData();
    formData.append('file', state.videoFile);
    formData.append('action', 'process');
    
    isProcessing = true;
    processingStartTime = Date.now();
    submitBtn.disabled = true;
    submitText.style.display = 'none';
    submitLoader.style.display = 'inline-block';
    processingSection.style.display = 'block';
    hideError();
    progressFill.style.width = '10%';
    progressText.textContent = 'Загрузка файла на сервер...';
    
    try {
        const serverUrl = getServerUrl();
        
        // Создаем AbortController для таймаута
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 600000); // 10 минут таймаут
        
        const response = await fetch(`${serverUrl}/admin/process-video`, {
            method: 'POST',
            body: formData,
            signal: controller.signal,
            // Не устанавливаем Content-Type, браузер сам установит с boundary для multipart/form-data
        });
        
        clearTimeout(timeoutId);
        
        if (!response.ok) {
            // Пытаемся получить JSON ошибку
            let errorMessage = `Ошибка ${response.status}: ${response.statusText}`;
            try {
                const errorData = await response.json();
                errorMessage = errorData.error || errorData.message || errorMessage;
            } catch (e) {
                // Если не JSON, читаем как текст
                const text = await response.text();
                if (text) {
                    errorMessage = `Ошибка ${response.status}: ${text.substring(0, 200)}`;
                }
            }
            throw new Error(errorMessage);
        }
        
        progressFill.style.width = '50%';
        progressText.textContent = 'Сжатие видео до 720p...';
        
        // Проверяем Content-Type перед парсингом JSON
        const contentType = response.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
            const text = await response.text();
            console.error('Неожиданный ответ от сервера:', text.substring(0, 500));
            throw new Error('Сервер вернул неожиданный ответ. Проверьте логи контейнера.');
        }
        
        const result = await response.json();
        
        if (!result.success) {
            throw new Error(result.error || 'Ошибка обработки видео');
        }
        
        progressFill.style.width = '100%';
        progressText.textContent = 'Видео обработано! Извлечение кадров...';
        
        // Сохраняем данные
        state.videoId = result.video_id;
        state.compressedVideoPath = result.compressed_video_path;
        state.frames = result.frames || [];
        
        // Переходим к выбору категории
        isProcessing = false;
        processingStartTime = null;
        setTimeout(() => {
            processingSection.style.display = 'none';
            updateStep('category');
        }, 1000);
        
    } catch (error) {
        isProcessing = false;
        processingStartTime = null;
        console.error('Ошибка:', error);
        
        // Проверяем тип ошибки
        let errorMessage = 'Произошла ошибка при обработке видео';
        if (error.name === 'AbortError') {
            errorMessage = 'Превышено время ожидания. Файл слишком большой или сервер не отвечает.';
        } else if (error.message) {
            errorMessage = error.message;
        }
        
        showError(errorMessage);
        // НЕ сбрасываем форму полностью, только кнопку
        submitBtn.disabled = false;
        submitText.style.display = 'inline';
        submitLoader.style.display = 'none';
        processingSection.style.display = 'none';
        progressFill.style.width = '0%';
        
        // Предотвращаем перезагрузку страницы
        return false;
    }
    });
    
    uploadForm.setAttribute('onsubmit', 'return false;');
}

// Обработка выбора категории
function initCategoryHandlers() {
    document.querySelectorAll('.category-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.category-btn').forEach(b => b.classList.remove('selected'));
            btn.classList.add('selected');
            state.selectedCategory = btn.dataset.category;
            const nextToFramesBtn = document.getElementById('nextToFramesBtn');
            if (nextToFramesBtn) {
                nextToFramesBtn.disabled = false;
            }
        });
    });
    
    // Переход к выбору обложки
    const nextToFramesBtn = document.getElementById('nextToFramesBtn');
    if (nextToFramesBtn) {
        nextToFramesBtn.addEventListener('click', () => {
            if (!state.selectedCategory) {
                showError('Пожалуйста, выберите категорию');
                return;
            }
            
            // Загружаем кадры, если они еще не загружены
            if (state.frames.length === 0) {
                loadFrames();
            } else {
                displayFrames();
                updateStep('frames');
            }
        });
    }
}

// Загрузка кадров
async function loadFrames() {
    if (!state.videoId) {
        showError('Видео не обработано');
        return;
    }
    
    try {
        processingSection.style.display = 'block';
        progressFill.style.width = '30%';
        progressText.textContent = 'Извлечение кадров из видео...';
        
        const formData = new FormData();
        formData.append('video_id', state.videoId);
        
        const serverUrl = getServerUrl();
        const response = await fetch(`${serverUrl}/admin/extract-frames`, {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Ошибка извлечения кадров');
        }
        
        const result = await response.json();
        
        if (!result.success) {
            throw new Error(result.error || 'Ошибка извлечения кадров');
        }
        
        state.frames = result.frames || [];
        displayFrames();
        updateStep('frames');
        processingSection.style.display = 'none';
        
    } catch (error) {
        console.error('Ошибка:', error);
        showError(error.message || 'Произошла ошибка при извлечении кадров');
        processingSection.style.display = 'none';
    }
}

// Отображение кадров
function displayFrames() {
    const framesGrid = document.getElementById('framesGrid');
    framesGrid.innerHTML = '';
    
    if (state.frames.length === 0) {
        framesGrid.innerHTML = '<p>Кадры не найдены</p>';
        return;
    }
    
    state.frames.forEach((frame, index) => {
        const frameDiv = document.createElement('div');
        frameDiv.className = 'frame-item selectable';
        frameDiv.dataset.index = index;
        
        // Преобразуем относительный URL в абсолютный, если нужно
        let frameUrl = frame.url;
        if (frameUrl.startsWith('/')) {
            // Если URL относительный, добавляем полный адрес сервера
            const serverUrl = getServerUrl();
            frameUrl = `${serverUrl}${frameUrl}`;
        }
        
        frameDiv.innerHTML = `
            <div class="frame-image">
                <img src="${frameUrl}" alt="${frame.filename}" onerror="console.error('Ошибка загрузки кадра:', '${frameUrl}'); this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI2RkZCIvPjx0ZXh0IHg9IjUwJSIgeT0iNTAlIiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTQiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGR5PSIuM2VtIj5JbWFnZTwvdGV4dD48L3N2Zz4='">
            </div>
            <div class="frame-info">
                <p class="frame-name">Кадр ${index + 1}</p>
            </div>
        `;
        
        frameDiv.addEventListener('click', () => {
            document.querySelectorAll('.frame-item.selectable').forEach(item => {
                item.classList.remove('selected');
            });
            frameDiv.classList.add('selected');
            state.selectedFrame = frame;
            document.getElementById('nextToMetadataBtn').disabled = false;
        });
        
        framesGrid.appendChild(frameDiv);
    });
}

// Инициализация обработчиков метаданных и сохранения
function initMetadataHandlers() {
    // Переход к метаданным
    const nextToMetadataBtn = document.getElementById('nextToMetadataBtn');
    if (nextToMetadataBtn) {
        nextToMetadataBtn.addEventListener('click', () => {
            if (!state.selectedFrame) {
                showError('Пожалуйста, выберите обложку');
                return;
            }
            updateStep('metadata');
        });
    }
    
    // Обработка сохранения
    const metadataForm = document.getElementById('metadataForm');
    if (!metadataForm) {
        console.error('Форма metadataForm не найдена!');
        return;
    }
    
    metadataForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    e.stopPropagation(); // Предотвращаем всплытие события
    
    if (isProcessing) {
        console.warn('Уже идет обработка, игнорируем запрос');
        return false;
    }
    
    if (!state.selectedCategory || !state.selectedFrame || !state.videoId) {
        showError('Не все данные заполнены');
        return false;
    }
    
    const title = document.getElementById('titleInput').value.trim();
    if (!title) {
        showError('Пожалуйста, введите название видео');
        return false;
    }
    
    const saveBtn = document.getElementById('saveBtn');
    const saveText = document.getElementById('saveText');
    const saveLoader = document.getElementById('saveLoader');
    
    isProcessing = true;
    processingStartTime = Date.now();
    saveBtn.disabled = true;
    saveText.style.display = 'none';
    saveLoader.style.display = 'inline-block';
    processingSection.style.display = 'block';
    progressFill.style.width = '30%';
    progressText.textContent = 'Сохранение в Supabase...';
    
    try {
        const formData = new FormData();
        formData.append('video_id', state.videoId);
        formData.append('category', state.selectedCategory);
        formData.append('frame_path', state.selectedFrame.local_path || state.selectedFrame.url);
        formData.append('title', title);
        formData.append('description', document.getElementById('descriptionInput').value.trim());
        formData.append('format', document.getElementById('formatSelect').value);
        
        const serverUrl = getServerUrl();
        
        // Создаем AbortController для таймаута
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 300000); // 5 минут таймаут
        
        const response = await fetch(`${serverUrl}/admin/save-to-portfolio`, {
            method: 'POST',
            body: formData,
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (!response.ok) {
            // Пытаемся получить JSON ошибку
            let errorMessage = `Ошибка ${response.status}: ${response.statusText}`;
            try {
                const errorData = await response.json();
                errorMessage = errorData.error || errorData.message || errorMessage;
            } catch (e) {
                // Если не JSON, читаем как текст
                const text = await response.text();
                if (text) {
                    errorMessage = `Ошибка ${response.status}: ${text.substring(0, 200)}`;
                }
            }
            throw new Error(errorMessage);
        }
        
        progressFill.style.width = '100%';
        progressText.textContent = 'Успешно сохранено!';
        
        const result = await response.json();
        
        isProcessing = false;
        processingStartTime = null;
        setTimeout(() => {
            alert('Видео успешно добавлено в портфолио!');
            resetAll();
        }, 1000);
        
    } catch (error) {
        isProcessing = false;
        processingStartTime = null;
        console.error('Ошибка:', error);
        
        // Проверяем тип ошибки
        let errorMessage = 'Произошла ошибка при сохранении';
        if (error.name === 'AbortError') {
            errorMessage = 'Превышено время ожидания. Попробуйте еще раз.';
        } else if (error.message) {
            errorMessage = error.message;
        }
        
        showError(errorMessage);
        saveBtn.disabled = false;
        saveText.style.display = 'inline';
        saveLoader.style.display = 'none';
        processingSection.style.display = 'none';
        
        // Предотвращаем перезагрузку страницы
        return false;
    }
    });
    
    metadataForm.setAttribute('onsubmit', 'return false;');
}

function resetForm() {
    state.videoFile = null;
    fileInput.value = '';
    fileName.style.display = 'none';
    submitBtn.disabled = true;
    submitText.style.display = 'inline';
    submitLoader.style.display = 'none';
    processingSection.style.display = 'none';
    progressFill.style.width = '0%';
}

function resetAll() {
    resetForm();
    state = {
        videoFile: null,
        compressedVideoPath: null,
        frames: [],
        selectedFrame: null,
        selectedCategory: null,
        videoId: null
    };
    
    // Сбрасываем флаг обработки при полном сбросе
    isProcessing = false;
    processingStartTime = null;
    
    document.querySelectorAll('.category-btn').forEach(btn => btn.classList.remove('selected'));
    document.getElementById('nextToFramesBtn').disabled = true;
    document.getElementById('nextToMetadataBtn').disabled = true;
    document.getElementById('framesGrid').innerHTML = '';
    document.getElementById('metadataForm').reset();
    
    updateStep('upload');
}

// Определяем URL сервера
function getServerUrl() {
    // Всегда используем порт 5000 для Flask сервера
    // Независимо от того, на каком порту открыта страница (5500 для Live Server, file:// и т.д.)
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        return 'http://localhost:5000';
    }
    // Если страница открыта через file://, используем localhost:5000
    if (window.location.protocol === 'file:') {
        return 'http://localhost:5000';
    }
    // Иначе используем тот же хост, но порт 5000
    return `${window.location.protocol}//${window.location.hostname}:5000`;
}

// ============================================
// МЕНЕДЖЕР ПРОЕКТОВ
// ============================================

let portfolioItems = [];

/**
 * Инициализация менеджера проектов
 */
function initPortfolioManager() {
    // Переключение вкладок
    const tabButtons = document.querySelectorAll('.admin-tab-btn');
    const tabContents = document.querySelectorAll('.tab-content[id$="TabContent"]');
    
    tabButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const tabName = btn.dataset.tab;
            
            // Обновляем активные кнопки
            tabButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            // Обновляем активные вкладки
            tabContents.forEach(content => {
                content.classList.remove('active');
                content.style.display = 'none';
            });
            const targetContent = document.getElementById(`${tabName}TabContent`);
            if (targetContent) {
                targetContent.classList.add('active');
                targetContent.style.display = 'block';
                console.log(`Вкладка ${tabName} активирована, display:`, targetContent.style.display);
            } else {
                console.error(`Вкладка ${tabName}TabContent не найдена!`);
            }
            
            // Если переключились на менеджер, загружаем список работ
            if (tabName === 'manage') {
                // Небольшая задержка, чтобы убедиться, что вкладка отобразилась
                setTimeout(() => {
                    loadPortfolioItems();
                }, 100);
            }
        });
    });
    
    // Закрытие модального окна редактирования
    const editModal = document.getElementById('editModal');
    const editModalClose = document.getElementById('editModalClose');
    const editCancelBtn = document.getElementById('editCancelBtn');
    
    if (editModalClose) {
        editModalClose.addEventListener('click', () => {
            editModal.classList.remove('active');
        });
    }
    
    if (editCancelBtn) {
        editCancelBtn.addEventListener('click', () => {
            editModal.classList.remove('active');
        });
    }
    
    // Закрытие по клику вне модального окна
    if (editModal) {
        editModal.addEventListener('click', (e) => {
            if (e.target === editModal) {
                editModal.classList.remove('active');
            }
        });
    }
    
    // Обработка формы редактирования
    const editForm = document.getElementById('editForm');
    if (editForm) {
        editForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            await savePortfolioItem();
        });
    }
}

/**
 * Загружает список работ портфолио
 */
async function loadPortfolioItems() {
    const container = document.getElementById('portfolioListContainer');
    if (!container) {
        console.error('Контейнер portfolioListContainer не найден!');
        return;
    }
    
    console.log('Начинаем загрузку работ портфолио...');
    
    container.innerHTML = `
        <div class="loading-state">
            <div class="loader" style="margin: 0 auto;"></div>
            <p style="margin-top: 20px;">Загрузка работ...</p>
        </div>
    `;
    
    try {
        // Импортируем и инициализируем Supabase
        const { getAllPortfolioItems, initSupabase } = await import('./supabase-client.js');
        console.log('Функции импортированы');
        
        // Убеждаемся, что Supabase инициализирован
        const initResult = initSupabase();
        if (!initResult) {
            throw new Error('Не удалось инициализировать Supabase. Проверьте конфигурацию в supabase/config.js');
        }
        console.log('Supabase инициализирован');
        
        portfolioItems = await getAllPortfolioItems();
        console.log('Получено работ:', portfolioItems.length);
        console.log('Данные работ:', portfolioItems);
        
        renderPortfolioItems();
    } catch (error) {
        console.error('Ошибка загрузки работ:', error);
        console.error('Стек ошибки:', error.stack);
        container.innerHTML = `
            <div class="error-section">
                <div class="error-message">Ошибка загрузки работ: ${error.message}</div>
                <div style="margin-top: 10px; font-size: 12px; color: var(--color-text-secondary);">
                    Проверьте консоль браузера для подробностей
                </div>
            </div>
        `;
    }
}

/**
 * Отображает список работ портфолио
 */
function renderPortfolioItems() {
    const container = document.getElementById('portfolioListContainer');
    if (!container) {
        console.error('Контейнер portfolioListContainer не найден при рендеринге!');
        return;
    }
    
    // Проверяем видимость контейнера
    const parentTab = container.closest('.tab-content');
    if (parentTab) {
        const isVisible = parentTab.classList.contains('active') || 
                         window.getComputedStyle(parentTab).display !== 'none';
        console.log('Вкладка видима:', isVisible, 'Display:', window.getComputedStyle(parentTab).display);
    }
    
    console.log('Рендерим работы. Количество:', portfolioItems?.length || 0);
    console.log('Контейнер найден:', !!container, 'Parent:', container.parentElement?.className);
    
    if (!portfolioItems || portfolioItems.length === 0) {
        console.log('Список работ пуст, показываем пустое состояние');
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">📁</div>
                <p>Работы не найдены</p>
            </div>
        `;
        return;
    }
    
    const categoryNames = {
        'ekspertnye': 'Экспертные',
        'hr': 'HR-видео',
        'ohvatnye': 'Охватные',
        'reklamnye': 'Рекламные'
    };
    
    const formatNames = {
        '9-16': '9:16 (вертикальный)',
        '16-9': '16:9 (горизонтальный)',
        '1-1': '1:1 (квадратный)'
    };
    
    try {
        const html = `
            <div class="portfolio-list">
                ${portfolioItems.map(item => {
                    // Безопасная обработка данных
                    const itemId = item.id || '';
                    const imageUrl = item.image_url || 'assets/placeholder.jpg';
                    const title = (item.title || 'Без названия').replace(/'/g, "&#39;").replace(/"/g, "&quot;");
                    const description = (item.description || 'Нет описания').replace(/'/g, "&#39;").replace(/"/g, "&quot;");
                    const isPublished = item.is_published !== false;
                    const category = categoryNames[item.category] || item.category || 'Не указана';
                    const format = formatNames[item.format] || item.format || 'Не указан';
                    
                    return `
                        <div class="portfolio-item-card ${!isPublished ? 'hidden' : ''}" data-id="${itemId}">
                            <img src="${imageUrl}" alt="${title}" class="portfolio-item-preview" 
                                 onerror="this.src='assets/placeholder.jpg'">
                            <div class="portfolio-item-info">
                                <div class="portfolio-item-title">${title}</div>
                                <div class="portfolio-item-description">${description}</div>
                                <div class="portfolio-item-meta">
                                    <span>📁 ${category}</span>
                                    <span>📐 ${format}</span>
                                    <span>${isPublished ? '✅ Опубликовано' : '❌ Скрыто'}</span>
                                </div>
                            </div>
                            <div class="portfolio-item-actions">
                                <button class="btn-edit" onclick="editPortfolioItem('${itemId}')">Редактировать</button>
                                <button class="btn-toggle-visibility ${!isPublished ? 'hidden' : ''}" 
                                        onclick="togglePortfolioVisibility('${itemId}', ${isPublished})">
                                    ${isPublished ? 'Скрыть' : 'Показать'}
                                </button>
                            </div>
                        </div>
                    `;
                }).join('')}
            </div>
        `;
        
        container.innerHTML = html;
        console.log('Работы успешно отображены');
        console.log('HTML контейнера после рендеринга:', container.innerHTML.substring(0, 200));
        console.log('Количество дочерних элементов:', container.children.length);
        
        // Принудительно проверяем видимость
        if (container.children.length > 0) {
            const firstChild = container.children[0];
            console.log('Первый дочерний элемент:', firstChild.className);
            console.log('Видимость первого элемента:', window.getComputedStyle(firstChild).display);
        }
    } catch (error) {
        console.error('Ошибка при рендеринге работ:', error);
        container.innerHTML = `
            <div class="error-section">
                <div class="error-message">Ошибка отображения работ: ${error.message}</div>
            </div>
        `;
    }
}

/**
 * Редактирует работу портфолио
 */
async function editPortfolioItem(id) {
    const item = portfolioItems.find(i => i.id === id);
    if (!item) {
        showError('Работа не найдена');
        return;
    }
    
    const editModal = document.getElementById('editModal');
    const editForm = document.getElementById('editForm');
    
    // Заполняем форму данными
    document.getElementById('editItemId').value = item.id;
    document.getElementById('editTitleInput').value = item.title || '';
    document.getElementById('editDescriptionInput').value = item.description || '';
    document.getElementById('editFormatSelect').value = item.format || '9-16';
    document.getElementById('editCategorySelect').value = item.category || 'reklamnye';
    document.getElementById('editIsPublishedInput').checked = item.is_published !== false;
    
    editModal.classList.add('active');
}

/**
 * Сохраняет изменения работы портфолио
 */
async function savePortfolioItem() {
    const editSaveBtn = document.getElementById('editSaveBtn');
    const editSaveText = document.getElementById('editSaveText');
    const editSaveLoader = document.getElementById('editSaveLoader');
    const editForm = document.getElementById('editForm');
    
    const formData = new FormData(editForm);
    const id = formData.get('id');
    
    const updates = {
        title: formData.get('title'),
        description: formData.get('description') || '',
        format: formData.get('format'),
        category: formData.get('category'),
        is_published: formData.get('is_published') === 'on'
    };
    
    editSaveBtn.disabled = true;
    editSaveText.style.display = 'none';
    editSaveLoader.style.display = 'inline-block';
    
    try {
        const { updatePortfolioItem } = await import('./supabase-client.js');
        const result = await updatePortfolioItem(id, updates);
        
        if (result.success) {
            // Обновляем локальный список
            const index = portfolioItems.findIndex(i => i.id === id);
            if (index !== -1) {
                portfolioItems[index] = { ...portfolioItems[index], ...updates };
            }
            
            renderPortfolioItems();
            editModal.classList.remove('active');
            showSuccess('Работа успешно обновлена');
        } else {
            showError(`Ошибка обновления: ${result.error}`);
        }
    } catch (error) {
        console.error('Ошибка сохранения:', error);
        showError(`Ошибка сохранения: ${error.message}`);
    } finally {
        editSaveBtn.disabled = false;
        editSaveText.style.display = 'inline';
        editSaveLoader.style.display = 'none';
    }
}

/**
 * Переключает видимость работы
 */
async function togglePortfolioVisibility(id, currentState) {
    const newState = !currentState;
    
    console.log('Переключение видимости работы:', id, 'с', currentState, 'на', newState);
    
    try {
        const { updatePortfolioItem } = await import('./supabase-client.js');
        
        // Убеждаемся, что передаем boolean значение
        const updates = { 
            is_published: Boolean(newState)
        };
        
        console.log('Отправка обновления:', updates);
        
        const result = await updatePortfolioItem(id, updates);
        
        if (result.success) {
            // Обновляем локальный список
            const index = portfolioItems.findIndex(i => i.id === id);
            if (index !== -1) {
                portfolioItems[index].is_published = newState;
            }
            
            renderPortfolioItems();
            showSuccess(`Работа ${newState ? 'опубликована' : 'скрыта'}`);
        } else {
            console.error('Ошибка обновления:', result);
            showError(`Ошибка: ${result.error || 'Неизвестная ошибка'}`);
        }
    } catch (error) {
        console.error('Ошибка переключения видимости:', error);
        console.error('Стек ошибки:', error.stack);
        showError(`Ошибка: ${error.message || 'Неизвестная ошибка'}`);
    }
}

/**
 * Показывает сообщение об успехе
 */
function showSuccess(message) {
    // Можно добавить toast-уведомление или использовать существующую систему ошибок
    const errorSection = document.getElementById('errorSection');
    const errorMessage = document.getElementById('errorMessage');
    if (errorSection && errorMessage) {
        errorMessage.textContent = message;
        errorMessage.style.color = '#48bb78';
        errorSection.style.display = 'block';
        setTimeout(() => {
            errorSection.style.display = 'none';
        }, 3000);
    }
}

// Делаем функции глобальными для использования в onclick
window.editPortfolioItem = editPortfolioItem;
window.togglePortfolioVisibility = togglePortfolioVisibility;

window.addEventListener('DOMContentLoaded', () => {
    if (!initDOMElements()) {
        console.error('Ошибка инициализации DOM элементов!');
        return;
    }
    
    initEventHandlers();
    initFormHandlers();
    initCategoryHandlers();
    initMetadataHandlers();
    initPortfolioManager(); // Инициализируем менеджер проектов
});

window.addEventListener('load', async () => {
    const serverUrl = getServerUrl();
    
    try {
        const healthResponse = await fetch(`${serverUrl}/health`);
        if (!healthResponse.ok) {
            throw new Error(`Сервер недоступен: ${healthResponse.status}`);
        }
        const healthData = await healthResponse.json();
        
        if (healthData.ffmpeg === 'not_found') {
            showError('ВНИМАНИЕ: FFmpeg не установлен на сервере. Установите FFmpeg для работы приложения.');
        }
        
        try {
            const adminResponse = await fetch(`${serverUrl}/admin/test`);
            if (!adminResponse.ok) {
                console.warn('Админ-эндпоинт недоступен. Убедитесь, что Flask сервер перезагружен.');
            }
        } catch (adminError) {
            console.warn('Не удалось проверить админ-эндпоинт:', adminError);
        }
        
    } catch (error) {
        console.error('Ошибка проверки сервера:', error);
        showError(`Не удалось подключиться к серверу: ${error.message}. Убедитесь, что Flask сервер запущен на порту 5000.`);
    }
});
