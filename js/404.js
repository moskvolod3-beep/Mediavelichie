/**
 * 404 Page functionality
 * Handles redirect countdown and navigation
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize navigation
    if (typeof initNavigation === 'function') {
        initNavigation('home'); // Use 'home' as default since 404 is not in the menu
    }
    
    // Initialize footer
    if (typeof initFooter === 'function') {
        initFooter();
    }
    
    // Countdown and redirect logic
    const countdownElement = document.getElementById('countdown');
    const redirectLink = document.querySelector('.error-404-link');
    let countdown = 5;
    let countdownInterval;
    
    if (countdownElement) {
        countdownInterval = setInterval(() => {
            countdown--;
            countdownElement.textContent = countdown;
            
            if (countdown <= 0) {
                clearInterval(countdownInterval);
                window.location.href = 'index.html';
            }
        }, 1000);
    }
    
    // Handle manual redirect
    if (redirectLink) {
        redirectLink.addEventListener('click', function(e) {
            e.preventDefault();
            if (countdownInterval) {
                clearInterval(countdownInterval);
            }
            window.location.href = 'index.html';
        });
    }
    
    // Handle order button click - try to open popup or redirect
    const orderBtn = document.querySelector('.error-404-order-btn');
    if (orderBtn) {
        orderBtn.addEventListener('click', function(e) {
            e.preventDefault();
            // Check if order popup script is loaded and popup exists
            const popup = document.getElementById('orderPopup');
            if (popup) {
                // Popup exists, try to open it
                popup.classList.add('active');
                document.body.style.overflow = 'hidden';
                // Reset form state
                const formState = document.getElementById('orderPopupForm');
                const successState = document.getElementById('orderPopupSuccess');
                if (formState) formState.style.display = 'block';
                if (successState) successState.style.display = 'none';
            } else {
                // Fallback: redirect to contacts
                window.location.href = 'contacts.html';
            }
        });
    }
});
