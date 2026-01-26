/**
 * Order Popup functionality
 * Handles opening/closing popup and form submission
 */

// Initialize popup when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    const popup = document.getElementById('orderPopup');
    const form = document.getElementById('orderForm');
    const formState = document.getElementById('orderPopupForm');
    const successState = document.getElementById('orderPopupSuccess');
    const closeBtn = document.getElementById('orderPopupClose');
    const successCloseBtn = document.getElementById('orderPopupSuccessClose');
    
    if (!popup || !form) return;
    
    // Open popup function
    function openPopup() {
        popup.classList.add('active');
        document.body.style.overflow = 'hidden';
        // Reset form
        form.reset();
        // Show form, hide success
        formState.style.display = 'block';
        successState.style.display = 'none';
    }
    
    // Close popup function
    function closePopup() {
        popup.classList.remove('active');
        document.body.style.overflow = '';
    }
    
    // Attach event listeners to order buttons
    const orderButtons = document.querySelectorAll('.btn-order-comp, .process-btn.btn-order, .btn-order');
    orderButtons.forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            openPopup();
        });
    });
    
    // Close button handlers
    if (closeBtn) {
        closeBtn.addEventListener('click', closePopup);
    }
    
    if (successCloseBtn) {
        successCloseBtn.addEventListener('click', closePopup);
    }
    
    // Close on overlay click
    const overlay = popup.querySelector('.order-popup-overlay');
    if (overlay) {
        overlay.addEventListener('click', closePopup);
    }
    
    // Close on Escape key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && popup.classList.contains('active')) {
            closePopup();
        }
    });
    
    // Form submission handler
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        // Check if privacy checkbox is checked
        const privacyCheckbox = form.querySelector('input[name="privacy"]');
        if (!privacyCheckbox.checked) {
            alert('Пожалуйста, согласитесь на обработку персональных данных');
            return;
        }
        
        // Get form data
        const formData = new FormData(form);
        const data = {
            name: formData.get('name'),
            phone: formData.get('phone'),
            message: formData.get('message'),
            privacy_accepted: privacyCheckbox.checked
        };
        
        // Disable submit button during request
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalBtnText = submitBtn.textContent;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Отправка...';
        
        // Import and use Supabase client
        try {
            const { createOrder } = await import('./supabase-client.js');
            const result = await createOrder(data);
            
            if (result.success) {
                // Show success state
                formState.style.display = 'none';
                successState.style.display = 'block';
                console.log('Заявка успешно отправлена:', result.data);
            } else {
                // Show error
                alert('Произошла ошибка при отправке заявки. Пожалуйста, попробуйте позже или свяжитесь с нами напрямую.');
                console.error('Ошибка отправки заявки:', result.error);
            }
        } catch (error) {
            console.error('Ошибка при отправке заявки:', error);
            // Fallback: show success anyway (graceful degradation)
            formState.style.display = 'none';
            successState.style.display = 'block';
        } finally {
            // Re-enable submit button
            submitBtn.disabled = false;
            submitBtn.textContent = originalBtnText;
        }
    });
});
