/**
 * Компонент подвала (Footer)
 * Используется на всех страницах сайта
 */

function createFooter() {
    return `
        <footer class="footer">
            <div class="footer-top">
                <div class="footer-container">
                    <img src="assets/Logo dark.svg" alt="Логотип Медиа Величия" class="footer-logo">
                    <div class="footer-column footer-column-brandup">
                        <a href="brandup.html" class="footer-title footer-title-link">Брендап</a>
                        <ul class="footer-links">
                            <li><a href="brandup.html#viewer-path" class="footer-link">Путь зрителя</a></li>
                            <li><a href="brandup.html#gallery" class="footer-link">Кейсы</a></li>
                            <li><a href="brandup.html#history" class="footer-link">История кейса</a></li>
                        </ul>
                    </div>
                    <div class="footer-column footer-column-services">
                        <a href="services.html" class="footer-title footer-title-link">Услуги</a>
                        <ul class="footer-links">
                            <li><a href="services.html#faq" class="footer-link">Частые вопросы</a></li>
                        </ul>
                    </div>
                    <div class="footer-column footer-column-portfolio">
                        <a href="portfolio.html" class="footer-title footer-title-link">Портфолио</a>
                        <ul class="footer-links">
                            <li><a href="portfolio.html#filter-ohvatnye" class="footer-link portfolio-filter-link" data-category="ohvatnye">Охватные</a></li>
                            <li><a href="portfolio.html#filter-ekspertnye" class="footer-link portfolio-filter-link" data-category="ekspertnye">Экспертные</a></li>
                            <li><a href="portfolio.html#filter-reklamnye" class="footer-link portfolio-filter-link" data-category="reklamnye">Рекламные</a></li>
                            <li><a href="portfolio.html#filter-hr" class="footer-link portfolio-filter-link" data-category="hr">HR-видео</a></li>
                        </ul>
                    </div>
                    <div class="footer-column footer-column-contacts">
                        <a href="contacts.html" class="footer-title footer-title-link">Контакты</a>
                        <ul class="footer-links">
                            <li><a href="contacts.html#form" class="footer-link contacts-form-link">Форма</a></li>
                            <li><a href="tel:+79854586284" class="footer-link">+7 985 458 62 84</a></li>
                            <li><a href="mailto:zakaz@medvel.ru" class="footer-link">zakaz@medvel.ru</a></li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="footer-bottom">
                <div class="footer-container footer-bottom-content">
                    <p class="copyright">© 2010–2025 «Медиа Величия»</p>
                    <div class="footer-social">
                        <a class="social-link" href="#"><img src="assets/instagram_ico.svg" class="social-icon" alt="Instagram"></a>
                        <a class="social-link" href="#"><img src="assets/youtube_ico.svg" class="social-icon" alt="YouTube"></a>
                        <a class="social-link" href="#"><img src="assets/telegram_ico.svg" class="social-icon" alt="Telegram"></a>
                        <a class="social-link" href="#"><img src="assets/vk_video_ico.svg" class="social-icon" alt="VK"></a>
                    </div>
                    <a href="privacy.html" class="footer-privacy">Политика конфиденциальности</a>
                </div>
            </div>
        </footer>
    `;
}

/**
 * Инициализация подвала
 */
function initFooter() {
    const footerContainer = document.querySelector('.footer-wrapper');
    if (footerContainer) {
        footerContainer.innerHTML = createFooter();
        
        // Добавляем обработчики для ссылок фильтров портфолио
        setupPortfolioFilterLinks();
        
        // Добавляем обработчики для ссылки формы контактов
        setupContactsFormLink();
    }
}

/**
 * Настройка обработчиков для ссылок фильтров портфолио
 */
function setupPortfolioFilterLinks() {
    const filterLinks = document.querySelectorAll('.portfolio-filter-link');
    
    filterLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const category = this.dataset.category;
            if (!category) return;
            
            // Проверяем, находимся ли мы на странице портфолио
            const isPortfolioPage = document.querySelector('.portfolio-page') !== null;
            
            if (isPortfolioPage) {
                // Если на странице портфолио, предотвращаем переход и применяем фильтр
                e.preventDefault();
                
                // Прокручиваем к секции портфолио
                const portfolioSection = document.querySelector('.portfolio-grid-section');
                if (portfolioSection) {
                    portfolioSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
                
                // Применяем фильтр после небольшой задержки для плавности
                // Используем несколько попыток на случай, если скрипт еще не загружен
                let attempts = 0;
                const maxAttempts = 10;
                const applyFilter = () => {
                    attempts++;
                    if (typeof filterPortfolio === 'function') {
                        filterPortfolio(category);
                    } else if (attempts < maxAttempts) {
                        setTimeout(applyFilter, 50);
                    }
                };
                setTimeout(applyFilter, 300);
            }
            // Если не на странице портфолио, ссылка работает как обычно (переход на portfolio.html#filter-xxx)
        });
    });
}

/**
 * Настройка обработчика для ссылки формы контактов
 */
function setupContactsFormLink() {
    const formLink = document.querySelector('.contacts-form-link');
    if (!formLink) return;
    
    formLink.addEventListener('click', function(e) {
        // Проверяем, находимся ли мы на странице контактов
        const isContactsPage = document.querySelector('.contacts-page') !== null;
        
        if (isContactsPage) {
            // Если на странице контактов, предотвращаем переход и прокручиваем к форме
            e.preventDefault();
            
            const formSection = document.querySelector('#form');
            if (formSection) {
                formSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }
        // Если не на странице контактов, ссылка работает как обычно (переход на contacts.html#form)
    });
}

// Автоматическая инициализация при загрузке
document.addEventListener('DOMContentLoaded', function () {
    initFooter();
});
