/**
 * Portfolio page functionality
 * Implements masonry layout with category filtering
 */

// Portfolio works data
const portfolioWorks = [
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

let currentCategory = 'all';

/**
 * Column-based masonry layout algorithm
 * Places items in columns, each next item goes to the shortest column
 */
function layoutMasonry() {
    const masonry = document.getElementById('portfolioMasonry');
    if (!masonry) return;
    
    const items = Array.from(masonry.querySelectorAll('.portfolio-item'));
    if (items.length === 0) return;
    
    const containerWidth = 1000;
    const numColumns = 4;
    const gap = 10;
    const columnWidth = (containerWidth - (gap * (numColumns - 1))) / numColumns; // ~245px
    
    // Initialize column heights array
    const columnHeights = new Array(numColumns).fill(0);
    
    // Process each item
    items.forEach((item) => {
        const content = item.querySelector('.content');
        const img = item.querySelector('img');
        
        if (!content || !img) return;
        
        // Determine column span (1 or 2 columns)
        const columnSpan = item.dataset.columnSpan ? parseInt(item.dataset.columnSpan) : 1;
        
        // Find the shortest column(s) that can fit this item
        let targetColumn = 0;
        let minHeight = columnHeights[0];
        
        // If item spans 2 columns, find the shortest pair of adjacent columns
        if (columnSpan === 2) {
            for (let i = 0; i <= numColumns - 2; i++) {
                const pairHeight = Math.max(columnHeights[i], columnHeights[i + 1]);
                if (pairHeight < minHeight) {
                    minHeight = pairHeight;
                    targetColumn = i;
                }
            }
        } else {
            // Find shortest single column
            for (let i = 1; i < numColumns; i++) {
                if (columnHeights[i] < minHeight) {
                    minHeight = columnHeights[i];
                    targetColumn = i;
                }
            }
        }
        
        // Calculate position
        const left = targetColumn * (columnWidth + gap);
        const top = minHeight;
        
        // Calculate displayed width
        const displayedWidth = columnSpan === 2 ? (columnWidth * 2 + gap) : columnWidth;
        
        // Set absolute positioning first to get accurate measurements
        item.style.position = 'absolute';
        item.style.left = `${left}px`;
        item.style.top = `${top}px`;
        item.style.width = `${displayedWidth}px`;
        
        // Set content width first
        content.style.width = '100%';
        
        // Get item height - use natural image dimensions if available
        let itemHeight = 0;
        
        if (img.naturalHeight > 0 && img.naturalWidth > 0) {
            // Use natural dimensions for accurate aspect ratio
            const aspectRatio = img.naturalHeight / img.naturalWidth;
            itemHeight = displayedWidth * aspectRatio;
        } else if (item.dataset.expectedHeight) {
            // Use expected height from data
            itemHeight = parseFloat(item.dataset.expectedHeight);
        } else {
            // Fallback: measure actual rendered height
            const rect = content.getBoundingClientRect();
            if (rect.height > 0) {
                itemHeight = rect.height;
            } else {
                // Last resort: use scrollHeight
                itemHeight = content.scrollHeight || displayedWidth * 0.6; // Default aspect ratio
            }
        }
        
        // Set item height
        item.style.height = `${itemHeight}px`;
        item.style.minHeight = `${itemHeight}px`;
        item.style.maxHeight = `${itemHeight}px`;
        
        // Set content to fill exactly - this ensures no gray gap
        content.style.height = `${itemHeight}px`;
        content.style.minHeight = `${itemHeight}px`;
        content.style.maxHeight = `${itemHeight}px`;
        
        // Update column heights
        if (columnSpan === 2) {
            const newHeight = top + itemHeight + gap;
            columnHeights[targetColumn] = newHeight;
            columnHeights[targetColumn + 1] = newHeight;
        } else {
            columnHeights[targetColumn] = top + itemHeight + gap;
        }
    });
    
    // Set container height to accommodate all items
    const maxHeight = Math.max(...columnHeights);
    masonry.style.height = `${maxHeight}px`;
}

/**
 * Resize all grid items (now uses column-based layout)
 */
function resizeAllGridItems() {
    layoutMasonry();
}

/**
 * Handle image load and recalculate layout
 */
function handleImageLoad(item) {
    layoutMasonry();
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
        
        // Create content wrapper
        const content = document.createElement('div');
        content.className = 'content';
        
        // Calculate grid-column span based on item width
        // Elements with width 490px should span 2 columns, 238px span 1 column
        const columnSpan = work.width > (columnWidth + gap / 2) ? 2 : 1;
        workItem.dataset.columnSpan = columnSpan;

        const img = document.createElement('img');
        img.src = work.image;
        img.alt = `Портфолио работа ${work.id}`;
        img.style.width = '100%';
        img.style.height = '100%';
        img.style.objectFit = 'cover';
        img.style.display = 'block';
        img.style.objectPosition = 'center';
        
        // Calculate expected height based on item width and aspect ratio
        const itemWidth = columnSpan === 2 ? (columnWidth * 2 + gap) : columnWidth;
        const aspectRatio = work.height / work.width;
        const expectedHeight = itemWidth * aspectRatio;
        
        // Set initial height to ensure proper sizing even before image loads
        // This ensures the container has the right size for the image
        content.style.height = `${expectedHeight}px`;
        content.style.width = '100%';
        workItem.dataset.expectedHeight = expectedHeight;

        const playOverlay = document.createElement('div');
        playOverlay.className = 'portfolio-play-overlay';
        const playIcon = document.createElement('img');
        playIcon.src = 'assets/play.svg';
        playIcon.alt = 'Play';
        playIcon.className = 'portfolio-play-icon';
        playOverlay.appendChild(playIcon);

        content.appendChild(img);
        workItem.appendChild(content);
        workItem.appendChild(playOverlay);
        masonry.appendChild(workItem);
        
        // Handle image load to recalculate grid position
        const recalculateHeight = () => {
            // Wait for image to fully render
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    const displayedWidth = content.getBoundingClientRect().width || content.offsetWidth;
                    if (displayedWidth <= 0) return;
                    
                    let finalHeight = 0;
                    
                    // Use actual rendered image height - this is the most accurate
                    const renderedImgHeight = img.getBoundingClientRect().height;
                    const renderedImgWidth = img.getBoundingClientRect().width;
                    
                    if (renderedImgHeight > 0 && renderedImgWidth > 0) {
                        // Use the actual rendered height of the image
                        finalHeight = renderedImgHeight;
                    } else if (img.naturalHeight > 0 && img.naturalWidth > 0) {
                        // Fallback: calculate from natural dimensions
                        const aspectRatio = img.naturalHeight / img.naturalWidth;
                        finalHeight = displayedWidth * aspectRatio;
                    } else {
                        finalHeight = parseFloat(workItem.dataset.expectedHeight) || expectedHeight;
                    }
                    
                    // Recalculate layout after image loads
                    layoutMasonry();
                });
            });
        };
        
        if (img.complete && img.naturalHeight !== 0) {
            // Image already loaded
            recalculateHeight();
        } else {
            // Wait for image to load
            img.addEventListener('load', recalculateHeight, { once: true });
            img.addEventListener('error', () => {
                // Keep expected height if image fails to load
                recalculateHeight();
            }, { once: true });
        }
    });
    
    // Layout items after a short delay to ensure images are loaded
    setTimeout(() => {
        layoutMasonry();
    }, 100);
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
}

/**
 * Initialize portfolio page
 */
function initPortfolio() {
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
            const validCategories = ['ohvatnye', 'ekspertnye', 'reklamnye', 'hr', 'sfery', 'all'];
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
            layoutMasonry();
        }, 100);
    });
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initPortfolio);
