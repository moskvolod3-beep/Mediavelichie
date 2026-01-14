class Carousel3D {
    constructor(container, options = {}) {
        this.container = typeof container === 'string' ? document.querySelector(container) : container;
        if (!this.container) return;

        this.root = this.container.querySelector('.carousel-root');
        this.items = Array.from(this.root.children);
        this.totalItems = this.items.length;

        this.options = Object.assign({
            radius: 400, // Distance from center
            cardWidth: 324,
            gap: 20,
            autoRotate: false,
            sensitivity: 0.5
        }, options);

        this.theta = 360 / this.totalItems;
        this.currentAngle = 0;
        this.targetAngle = 0;
        this.isDragging = false;
        this.startX = 0;
        this.startAngle = 0;

        this.init();
    }

    init() {
        this.container.style.perspective = '1000px';
        this.container.style.overflow = 'hidden';
        this.root.style.transformStyle = 'preserve-3d';
        this.root.style.width = '100%';
        this.root.style.height = '100%';
        this.root.style.position = 'relative';
        this.root.style.transition = 'transform 0.5s cubic-bezier(0.25, 1, 0.5, 1)'; // Smooth snap

        // Position items
        this.items.forEach((item, index) => {
            const angle = this.theta * index;
            // Convert degrees to radians for math if needed, but styling uses deg
            // transform: rotateY(angle) translateZ(radius)
            // But we want them facing OUTWARD? Or Inward?
            // "Carousel" usually faces outward.

            item.style.position = 'absolute';
            item.style.left = '50%';
            item.style.top = '50%';
            item.style.transformOrigin = 'center center';
            // Center the item
            item.style.marginLeft = `-${this.options.cardWidth / 2}px`;
            item.style.marginTop = `-${item.offsetHeight / 2}px`; // dynamic height? Or fixed.

            // Assign index for tracking
            item.dataset.index = index;
        });

        this.update();

        // Events
        this.container.addEventListener('mousedown', this.onDragStart.bind(this));
        this.container.addEventListener('touchstart', this.onDragStart.bind(this), { passive: false });

        window.addEventListener('mousemove', this.onDragMove.bind(this));
        window.addEventListener('touchmove', this.onDragMove.bind(this), { passive: false });

        window.addEventListener('mouseup', this.onDragEnd.bind(this));
        window.addEventListener('touchend', this.onDragEnd.bind(this));
    }

    update() {
        // Calculate dynamic radius based on angles? Or fixed.
        // options.radius.
        // We rotate the ROOT. Items are fixed relative to root?
        const radius = this.options.radius;

        this.items.forEach((item, index) => {
            const angle = this.theta * index;
            item.style.transform = `rotateY(${angle}deg) translateZ(${radius}px)`;
            item.style.backfaceVisibility = 'hidden'; // Hide back?
            // Or adjust opacity based on rotation relative to camera
        });

        // Rotate root
        this.root.style.transform = `translateZ(-${radius}px) rotateY(${this.currentAngle}deg)`;

        // Update Opacity/Depth sorting?
        // simple 3d css handles depth sorting (z-buffer).
        // To highlight active, we might need JS class.

        // Calculate "Active" index
        // Normalized angle
        let normalized = -this.currentAngle % 360;
        if (normalized < 0) normalized += 360;
        // active index is close to normalized / theta?
        // roughly.
    }

    onDragStart(e) {
        this.isDragging = true;
        this.startX = e.pageX || e.touches[0].pageX;
        this.startAngle = this.currentAngle;
        this.root.style.transition = 'none'; // Disable transition for drag
    }

    onDragMove(e) {
        if (!this.isDragging) return;
        e.preventDefault(); // Prevent scroll on touch
        const x = e.pageX || e.touches[0].pageX;
        const delta = (x - this.startX) * this.options.sensitivity;
        this.currentAngle = this.startAngle + delta; // Rotate RIGHT drags Left? 
        // usually drag left -> rotate negative (counter-clockwise).
        // If I drag left, x decreases. delta is negative. Angle decreases.
        this.update();
    }

    onDragEnd() {
        if (!this.isDragging) return;
        this.isDragging = false;

        // Snap to nearest item
        const snapAngle = Math.round(this.currentAngle / this.theta) * this.theta;
        this.currentAngle = snapAngle;
        this.root.style.transition = 'transform 0.5s cubic-bezier(0.25, 1, 0.5, 1)';
        this.update();
    }

    next() {
        this.currentAngle -= this.theta;
        this.root.style.transition = 'transform 0.5s cubic-bezier(0.25, 1, 0.5, 1)';
        this.update();
    }

    prev() {
        this.currentAngle += this.theta;
        this.root.style.transition = 'transform 0.5s cubic-bezier(0.25, 1, 0.5, 1)';
        this.update();
    }
}

// export or global
window.Carousel3D = Carousel3D;
