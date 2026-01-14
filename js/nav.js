/**
 * Компонент навигационного меню
 * Используется на всех страницах сайта
 */

function createNavigationMenu(currentPage = 'home') {
    const menuItems = [
        { href: 'index.html', text: 'ГЛАВНАЯ', id: 'home' },
        { href: 'brandup.html', text: 'БРЕНДАП', id: 'brandup' },
        { href: 'services.html', text: 'УСЛУГИ', id: 'services' },
        { href: 'portfolio.html', text: 'ПОРТФОЛИО', id: 'portfolio' },
        { href: 'contacts.html', text: 'КОНТАКТЫ', id: 'contacts' }
    ];

    let navHTML = '<nav class="hero-nav">';

    menuItems.forEach(item => {
        const isActive = item.id === currentPage ? ' active' : '';
        navHTML += `
            <a href="${item.href}" class="nav-link${isActive}">
                <img src="assets/arrow_main.svg" alt="" class="nav-link-arrow">
                <span class="nav-link-text">${item.text}</span>
            </a>
        `;
    });

    navHTML += '</nav>';

    return navHTML;
}

/**
 * Инициализация меню на странице
 * @param {string} currentPage - ID текущей страницы ('home', 'brandup', etc.)
 */
function initNavigation(currentPage = 'home') {
    const navContainer = document.querySelector('.hero-nav-container');
    if (navContainer) {
        navContainer.innerHTML = createNavigationMenu(currentPage);
    }
}

// Автоматическое определение текущей страницы и инициализация меню
document.addEventListener('DOMContentLoaded', function () {
    // Определяем текущую страницу по имени файла
    const currentPath = window.location.pathname;
    let currentPage = 'home'; // по умолчанию

    if (currentPath.includes('brandup.html')) {
        currentPage = 'brandup';
    } else if (currentPath.includes('services.html')) {
        currentPage = 'services';
    } else if (currentPath.includes('portfolio.html')) {
        currentPage = 'portfolio';
    } else if (currentPath.includes('project.html')) {
        currentPage = 'project';
    } else if (currentPath.includes('contacts.html')) {
        currentPage = 'contacts';
    } else if (currentPath.includes('index.html') || currentPath === '/' || currentPath.endsWith('/')) {
        currentPage = 'home';
    }

    // Инициализируем меню
    initNavigation(currentPage);
});


