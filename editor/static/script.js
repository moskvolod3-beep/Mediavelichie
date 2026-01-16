const uploadArea = document.getElementById('uploadArea');
const fileInput = document.getElementById('fileInput');
const uploadForm = document.getElementById('uploadForm');
const submitBtn = document.getElementById('submitBtn');
const submitText = document.getElementById('submitText');
const submitLoader = document.getElementById('submitLoader');
const fileName = document.getElementById('fileName');
const processingSection = document.getElementById('processingSection');
const progressFill = document.getElementById('progressFill');
const progressText = document.getElementById('progressText');
const errorSection = document.getElementById('errorSection');
const errorMessage = document.getElementById('errorMessage');

let selectedFile = null;

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

// Клик по области загрузки
uploadArea.addEventListener('click', () => {
    fileInput.click();
});

fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
        handleFileSelect(file);
    }
});

function handleFileSelect(file) {
    selectedFile = file;
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

// Обработка отправки формы
uploadForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!selectedFile) {
        showError('Пожалуйста, выберите файл');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('resolution', document.querySelector('input[name="resolution"]:checked').value);
    
    // Показываем процесс обработки
    submitBtn.disabled = true;
    submitText.style.display = 'none';
    submitLoader.style.display = 'inline-block';
    processingSection.style.display = 'block';
    hideError();
    progressFill.style.width = '30%';
    progressText.textContent = 'Загрузка файла на сервер...';
    
    try {
        const response = await fetch('/upload', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Ошибка обработки видео');
        }
        
        progressFill.style.width = '70%';
        progressText.textContent = 'Обработка видео...';
        
        // Получаем файл для скачивания
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `compressed_${document.querySelector('input[name="resolution"]:checked').value}p_${selectedFile.name}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        
        progressFill.style.width = '100%';
        progressText.textContent = 'Готово! Файл скачивается...';
        
        // Сбрасываем форму через 2 секунды
        setTimeout(() => {
            resetForm();
        }, 2000);
        
    } catch (error) {
        console.error('Ошибка:', error);
        showError(error.message || 'Произошла ошибка при обработке видео');
        resetForm();
    }
});

function resetForm() {
    selectedFile = null;
    fileInput.value = '';
    fileName.style.display = 'none';
    submitBtn.disabled = true;
    submitText.style.display = 'inline';
    submitLoader.style.display = 'none';
    processingSection.style.display = 'none';
    progressFill.style.width = '0%';
}

// Элементы для извлечения кадров
const framesUploadArea = document.getElementById('framesUploadArea');
const framesFileInput = document.getElementById('framesFileInput');
const framesForm = document.getElementById('framesForm');
const framesSubmitBtn = document.getElementById('framesSubmitBtn');
const framesSubmitText = document.getElementById('framesSubmitText');
const framesSubmitLoader = document.getElementById('framesSubmitLoader');
const framesFileName = document.getElementById('framesFileName');
const framesResult = document.getElementById('framesResult');
const framesGrid = document.getElementById('framesGrid');
const framesInfo = document.getElementById('framesInfo');
const intervalInput = document.getElementById('intervalInput');
const bucketCheckbox = document.getElementById('bucketCheckbox');

let selectedFramesFile = null;

// Переключение вкладок
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tabName = btn.dataset.tab;
        
        // Убираем active у всех вкладок и контента
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        // Активируем выбранную вкладку
        btn.classList.add('active');
        document.getElementById(`${tabName}Tab`).classList.add('active');
        
        // Скрываем результаты предыдущей вкладки
        framesResult.style.display = 'none';
        errorSection.style.display = 'none';
    });
});

// Обработка перетаскивания файла для кадров
framesUploadArea.addEventListener('dragover', (e) => {
    e.preventDefault();
    framesUploadArea.classList.add('dragover');
});

framesUploadArea.addEventListener('dragleave', () => {
    framesUploadArea.classList.remove('dragover');
});

framesUploadArea.addEventListener('drop', (e) => {
    e.preventDefault();
    framesUploadArea.classList.remove('dragover');
    
    const file = e.dataTransfer.files[0];
    if (file && file.type.startsWith('video/')) {
        handleFramesFileSelect(file);
    } else {
        showError('Пожалуйста, выберите видеофайл');
    }
});

framesUploadArea.addEventListener('click', () => {
    framesFileInput.click();
});

framesFileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
        handleFramesFileSelect(file);
    }
});

function handleFramesFileSelect(file) {
    selectedFramesFile = file;
    framesFileName.textContent = `Выбран файл: ${file.name} (${formatFileSize(file.size)})`;
    framesFileName.style.display = 'block';
    framesSubmitBtn.disabled = false;
    hideError();
}

// Обработка отправки формы извлечения кадров
framesForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!selectedFramesFile) {
        showError('Пожалуйста, выберите файл');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', selectedFramesFile);
    formData.append('interval', intervalInput.value);
    formData.append('bucket_enabled', bucketCheckbox.checked);
    
    // Показываем процесс обработки
    framesSubmitBtn.disabled = true;
    framesSubmitText.style.display = 'none';
    framesSubmitLoader.style.display = 'inline-block';
    processingSection.style.display = 'block';
    hideError();
    framesResult.style.display = 'none';
    progressFill.style.width = '10%';
    progressText.textContent = 'Загрузка файла на сервер...';
    
    try {
        const response = await fetch('/extract-frames', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Ошибка извлечения кадров');
        }
        
        progressFill.style.width = '50%';
        progressText.textContent = 'Извлечение кадров...';
        
        const result = await response.json();
        
        progressFill.style.width = '100%';
        progressText.textContent = 'Кадры извлечены!';
        
        // Отображаем результаты
        displayFramesResult(result);
        
        // Скрываем прогресс через 2 секунды
        setTimeout(() => {
            processingSection.style.display = 'none';
            progressFill.style.width = '0%';
        }, 2000);
        
    } catch (error) {
        console.error('Ошибка:', error);
        showError(error.message || 'Произошла ошибка при извлечении кадров');
        framesSubmitBtn.disabled = false;
        framesSubmitText.style.display = 'inline';
        framesSubmitLoader.style.display = 'none';
        processingSection.style.display = 'none';
    }
});

function displayFramesResult(result) {
    framesGrid.innerHTML = '';
    framesInfo.innerHTML = '';
    
    // Информация о результатах
    const info = document.createElement('div');
    info.className = 'frames-summary';
    info.innerHTML = `
        <p><strong>Извлечено кадров:</strong> ${result.frames_count}</p>
        <p><strong>Тип хранилища:</strong> ${result.bucket_enabled ? result.bucket_type.toUpperCase() : 'Локальное'}</p>
    `;
    framesInfo.appendChild(info);
    
    // Отображаем кадры
    result.frames.forEach((frame, index) => {
        const frameDiv = document.createElement('div');
        frameDiv.className = 'frame-item';
        frameDiv.innerHTML = `
            <div class="frame-image">
                <img src="${frame.url}" alt="${frame.filename}" onerror="this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI2RkZCIvPjx0ZXh0IHg9IjUwJSIgeT0iNTAlIiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTQiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGR5PSIuM2VtIj5JbWFnZTwvdGV4dD48L3N2Zz4='">
            </div>
            <div class="frame-info">
                <p class="frame-name">${frame.filename}</p>
                ${frame.url.startsWith('http') ? `<a href="${frame.url}" target="_blank" class="frame-link">Открыть</a>` : ''}
            </div>
        `;
        framesGrid.appendChild(frameDiv);
    });
    
    framesResult.style.display = 'block';
}

// Проверяем состояние сервера при загрузке
window.addEventListener('load', async () => {
    try {
        const response = await fetch('/health');
        const data = await response.json();
        if (data.ffmpeg === 'not_found') {
            showError('ВНИМАНИЕ: FFmpeg не установлен на сервере. Установите FFmpeg для работы приложения.');
        }
    } catch (error) {
        console.error('Ошибка проверки сервера:', error);
    }
});







