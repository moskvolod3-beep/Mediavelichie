// Микроанимации для главной страницы
document.addEventListener('DOMContentLoaded', () => {
    // Анимация появления элементов при скролле
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Элементы для анимации появления
    const animateElements = document.querySelectorAll(`
        .services-section .services-title,
        .services-section .services-info,
        .services-section .services-btn,
        .services-section .service-item
    `);

    animateElements.forEach((el, index) => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = `opacity 0.6s ease ${index * 0.1}s, transform 0.6s ease ${index * 0.1}s`;
        observer.observe(el);
    });

    // Отдельная анимация для секции портфолио при появлении на экране
    const portfolioSection = document.querySelector('.portfolio-section');
    if (portfolioSection) {
        const portfolioObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    // Анимация заголовка портфолио
                    const portfolioTitle = entry.target.querySelector('.portfolio-title');
                    if (portfolioTitle && !portfolioTitle.classList.contains('animate-in')) {
                        portfolioTitle.style.opacity = '0';
                        portfolioTitle.style.transform = 'translateY(30px)';
                        portfolioTitle.style.transition = 'opacity 0.6s ease 0.1s, transform 0.6s ease 0.1s';
                        setTimeout(() => {
                            portfolioTitle.classList.add('animate-in');
                            portfolioTitle.style.opacity = '1';
                            portfolioTitle.style.transform = 'translateY(0)';
                        }, 50);
                    }

                    // Анимация элементов портфолио последовательно
                    const portfolioItems = entry.target.querySelectorAll('.portfolio-item');
                    portfolioItems.forEach((item, index) => {
                        if (!item.classList.contains('animate-in')) {
                            item.style.opacity = '0';
                            item.style.transform = 'translateY(40px) scale(0.95)';
                            item.style.transition = `opacity 0.6s ease ${0.2 + index * 0.15}s, transform 0.6s ease ${0.2 + index * 0.15}s`;
                            setTimeout(() => {
                                item.classList.add('animate-in');
                                item.style.opacity = '1';
                                item.style.transform = 'translateY(0) scale(1)';
                            }, 100 + index * 150);
                        }
                    });

                    portfolioObserver.unobserve(entry.target);
                }
            });
        }, {
            threshold: 0.2,
            rootMargin: '0px 0px -100px 0px'
        });

        portfolioObserver.observe(portfolioSection);
    }

    // Отдельная анимация для секции направлений при появлении на экране
    const directionsSection = document.querySelector('.directions-section');
    if (directionsSection) {
        const directionsObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    // Анимация заголовка направлений
                    const directionsTitle = entry.target.querySelector('.directions-title');
                    if (directionsTitle && !directionsTitle.classList.contains('animate-in')) {
                        directionsTitle.style.opacity = '0';
                        directionsTitle.style.transform = 'translateY(30px)';
                        directionsTitle.style.transition = 'opacity 0.6s ease 0.1s, transform 0.6s ease 0.1s';
                        setTimeout(() => {
                            directionsTitle.classList.add('animate-in');
                            directionsTitle.style.opacity = '1';
                            directionsTitle.style.transform = 'translateY(0)';
                        }, 50);
                    }

                    // Анимация карточек направлений последовательно
                    const directionCards = entry.target.querySelectorAll('.direction-card');
                    directionCards.forEach((card, index) => {
                        if (!card.classList.contains('animate-in')) {
                            card.style.opacity = '0';
                            card.style.transform = 'translateY(40px) scale(0.95)';
                            card.style.transition = `opacity 0.6s ease ${0.2 + index * 0.15}s, transform 0.6s ease ${0.2 + index * 0.15}s`;
                            setTimeout(() => {
                                card.classList.add('animate-in');
                                card.style.opacity = '1';
                                card.style.transform = 'translateY(0) scale(1)';
                            }, 100 + index * 150);
                        }
                    });

                    directionsObserver.unobserve(entry.target);
                }
            });
        }, {
            threshold: 0.2,
            rootMargin: '0px 0px -100px 0px'
        });

        directionsObserver.observe(directionsSection);
    }

    // Анимация логотипа при загрузке
    const logo = document.querySelector('.logo-svg');
    if (logo) {
        logo.style.opacity = '0';
        logo.style.transform = 'scale(0.8)';
        setTimeout(() => {
            logo.style.transition = 'opacity 0.8s ease, transform 0.8s ease';
            logo.style.opacity = '1';
            logo.style.transform = 'scale(1)';
        }, 100);
    }

    // Анимация заголовка hero
    const heroTitle = document.querySelector('.hero-title');
    if (heroTitle) {
        const spans = heroTitle.querySelectorAll('span');
        spans.forEach((span, index) => {
            span.style.opacity = '0';
            span.style.transform = 'translateY(20px)';
            setTimeout(() => {
                span.style.transition = `opacity 0.8s ease ${index * 0.2}s, transform 0.8s ease ${index * 0.2}s`;
                span.style.opacity = '1';
                span.style.transform = 'translateY(0)';
            }, 300 + index * 200);
        });
    }

    // Анимация кнопки "Заказать"
    const orderBtn = document.querySelector('.btn-order');
    if (orderBtn) {
        orderBtn.style.opacity = '0';
        setTimeout(() => {
            orderBtn.style.transition = 'opacity 0.6s ease, border-radius 0.3s ease';
            orderBtn.style.opacity = '1';
        }, 800);
    }

    // Hover эффекты для карточек направлений
    const directionCards = document.querySelectorAll('.direction-card');
    directionCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
        });
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });

    // Hover эффекты для портфолио
    const portfolioItems = document.querySelectorAll('.portfolio-item');
    portfolioItems.forEach(item => {
        item.addEventListener('mouseenter', function() {
            const img = this.querySelector('.portfolio-img');
            if (img) {
                img.style.transform = 'scale(1.05)';
            }
        });
        item.addEventListener('mouseleave', function() {
            const img = this.querySelector('.portfolio-img');
            if (img) {
                img.style.transform = 'scale(1)';
            }
        });
    });

    // Анимация для элементов услуг
    const serviceItems = document.querySelectorAll('.service-item');
    serviceItems.forEach((item, index) => {
        item.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.02)';
            this.style.zIndex = '10';
        });
        item.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1)';
            this.style.zIndex = '1';
        });
    });
});
