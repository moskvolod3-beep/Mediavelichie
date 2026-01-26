/**
 * Page Transitions - Sliding animation between pages
 */

(function() {
    'use strict';
    
    // Check if browser supports CSS transitions
    const supportsTransitions = 'transition' in document.documentElement.style;
    
    if (!supportsTransitions) {
        return; // Exit if transitions not supported
    }
    
    // Add transition class to body
    document.documentElement.classList.add('page-transitions-enabled');
    
    // Handle all internal links
    function handleLinkClick(e) {
        const link = e.currentTarget;
        const href = link.getAttribute('href');
        
        // Skip if no href or special protocols
        if (!href || href.startsWith('#') || href.startsWith('mailto:') || href.startsWith('tel:')) {
            return;
        }
        
        // Skip if link has data-no-transition attribute
        if (link.hasAttribute('data-no-transition')) {
            return;
        }
        
        // Skip if link has specific classes that handle their own navigation
        if (link.classList.contains('portfolio-filter-link') || 
            link.classList.contains('contacts-form-link') ||
            link.classList.contains('footer-title-link')) {
            return;
        }
        
        // Check if it's an internal link
        let isInternal = false;
        try {
            const url = new URL(href, window.location.origin);
            if (url.origin === window.location.origin) {
                isInternal = true;
            }
        } catch (e) {
            // Relative URL - treat as internal
            isInternal = true;
        }
        
        if (!isInternal) {
            return; // External link, let browser handle it
        }
        
        // Prevent default navigation
        e.preventDefault();
        
        // Add exit animation class
        document.body.classList.add('page-exit');
        
        // Navigate after animation
        setTimeout(() => {
            window.location.href = href;
        }, 300); // Match CSS transition duration
    }
    
    // Attach event listeners when DOM is ready
    function init() {
        // Find all internal links
        const links = document.querySelectorAll('a[href]');
        
        links.forEach(link => {
            const href = link.getAttribute('href');
            
            // Skip if it's an anchor link, mailto, tel, or external link
            if (href && !href.startsWith('#') && !href.startsWith('mailto:') && !href.startsWith('tel:')) {
                try {
                    const url = new URL(href, window.location.origin);
                    if (url.origin === window.location.origin) {
                        link.addEventListener('click', handleLinkClick);
                    }
                } catch (e) {
                    // Relative URL - treat as internal
                    link.addEventListener('click', handleLinkClick);
                }
            }
        });
        
        // Add enter animation when page loads
        document.body.classList.add('page-enter');
        
        // Remove enter class after animation completes
        setTimeout(() => {
            document.body.classList.remove('page-enter');
        }, 300);
    }
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
