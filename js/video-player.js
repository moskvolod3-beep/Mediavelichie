/**
 * Video Player - Custom video player with glassmorphism design
 */

(function() {
    'use strict';
    
    // Create video player HTML structure
    function createVideoPlayer() {
        const playerHTML = `
            <div class="video-player" id="videoPlayer">
                <div class="video-player-overlay"></div>
                <div class="video-player-content">
                    <button class="video-player-close" id="videoPlayerClose">&times;</button>
                    <div class="video-player-container">
                        <video class="video-player-video" id="videoPlayerVideo">
                            Ваш браузер не поддерживает воспроизведение видео.
                        </video>
                        <div class="video-player-controls" id="videoPlayerControls">
                            <div class="video-controls-left">
                                <button class="video-control-btn video-control-play" id="videoControlPlay" aria-label="Play/Pause">
                                    <svg class="play-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path d="M8 5v14l11-7z" fill="currentColor"/>
                                    </svg>
                                    <svg class="pause-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="display: none;">
                                        <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" fill="currentColor"/>
                                    </svg>
                                </button>
                                <div class="video-control-progress-wrapper">
                                    <div class="video-progress-bar" id="videoProgressBar">
                                        <div class="video-progress-filled" id="videoProgressFilled">
                                            <div class="video-progress-handle"></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="video-control-time">
                                    <span class="video-time-current" id="videoTimeCurrent">0:00</span>
                                    <span class="video-time-separator">/</span>
                                    <span class="video-time-total" id="videoTimeTotal">0:00</span>
                                </div>
                            </div>
                            <div class="video-controls-right">
                                <div class="video-volume-control">
                                    <button class="video-control-btn video-control-volume" id="videoControlVolume" aria-label="Volume">
                                        <svg class="volume-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                            <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z" fill="currentColor"/>
                                        </svg>
                                        <svg class="volume-muted-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="display: none;">
                                            <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z" fill="currentColor"/>
                                        </svg>
                                    </button>
                                    <div class="video-volume-slider-wrapper">
                                        <input type="range" class="video-volume-slider" id="videoVolumeSlider" min="0" max="100" value="100" aria-label="Volume">
                                    </div>
                                </div>
                                <button class="video-control-btn video-control-settings" id="videoControlSettings" aria-label="Settings">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.06-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.04.3-.07.63-.07.94s.02.64.06.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z" fill="currentColor"/>
                                    </svg>
                                </button>
                                <button class="video-control-btn video-control-fullscreen" id="videoControlFullscreen" aria-label="Fullscreen">
                                    <svg class="fullscreen-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z" fill="currentColor"/>
                                    </svg>
                                    <svg class="fullscreen-exit-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="display: none;">
                                        <path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z" fill="currentColor"/>
                                    </svg>
                                </button>
                            </div>
                        </div>
                        <div class="video-settings-menu" id="videoSettingsMenu" style="display: none;">
                            <div class="video-settings-item">
                                <label>Скорость воспроизведения</label>
                                <select id="videoPlaybackSpeed" class="video-settings-select">
                                    <option value="0.5">0.5x</option>
                                    <option value="0.75">0.75x</option>
                                    <option value="1" selected>1x</option>
                                    <option value="1.25">1.25x</option>
                                    <option value="1.5">1.5x</option>
                                    <option value="2">2x</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', playerHTML);
    }
    
    // Initialize video player
    let videoPlayer = null;
    let videoElement = null;
    let isPlaying = false;
    let isControlsVisible = true;
    let controlsTimeout = null;
    
    function initVideoPlayer() {
        createVideoPlayer();
        
        videoPlayer = document.getElementById('videoPlayer');
        videoElement = document.getElementById('videoPlayerVideo');
        const closeBtn = document.getElementById('videoPlayerClose');
        const overlay = videoPlayer.querySelector('.video-player-overlay');
        const playBtn = document.getElementById('videoControlPlay');
        const playIcon = playBtn.querySelector('.play-icon');
        const pauseIcon = playBtn.querySelector('.pause-icon');
        const progressBar = document.getElementById('videoProgressBar');
        const progressFilled = document.getElementById('videoProgressFilled');
        const volumeBtn = document.getElementById('videoControlVolume');
        const volumeIcon = volumeBtn.querySelector('.volume-icon');
        const volumeMutedIcon = volumeBtn.querySelector('.volume-muted-icon');
        const volumeSlider = document.getElementById('videoVolumeSlider');
        const fullscreenBtn = document.getElementById('videoControlFullscreen');
        const fullscreenIcon = fullscreenBtn.querySelector('.fullscreen-icon');
        const fullscreenExitIcon = fullscreenBtn.querySelector('.fullscreen-exit-icon');
        const settingsBtn = document.getElementById('videoControlSettings');
        const settingsMenu = document.getElementById('videoSettingsMenu');
        const playbackSpeedSelect = document.getElementById('videoPlaybackSpeed');
        const timeCurrent = document.getElementById('videoTimeCurrent');
        const timeTotal = document.getElementById('videoTimeTotal');
        
        // Close player
        function closePlayer() {
            if (videoElement) {
                videoElement.pause();
                videoElement.src = '';
                videoElement.load();
            }
            videoPlayer.classList.remove('active');
            document.body.style.overflow = '';
        }
        
        closeBtn.addEventListener('click', closePlayer);
        overlay.addEventListener('click', closePlayer);
        
        // Close on Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && videoPlayer.classList.contains('active')) {
                closePlayer();
            }
        });
        
        // Play/Pause
        playBtn.addEventListener('click', () => {
            if (videoElement.paused) {
                videoElement.play();
            } else {
                videoElement.pause();
            }
        });
        
        videoElement.addEventListener('play', () => {
            isPlaying = true;
            updatePlayButton();
        });
        
        videoElement.addEventListener('pause', () => {
            isPlaying = false;
            updatePlayButton();
        });
        
        function updatePlayButton() {
            if (isPlaying) {
                playIcon.style.display = 'none';
                pauseIcon.style.display = 'block';
            } else {
                playIcon.style.display = 'block';
                pauseIcon.style.display = 'none';
            }
        }
        
        // Progress bar
        function updateProgress() {
            if (videoElement.duration) {
                const percent = (videoElement.currentTime / videoElement.duration) * 100;
                progressFilled.style.width = percent + '%';
                timeCurrent.textContent = formatTime(videoElement.currentTime);
            }
        }
        
        videoElement.addEventListener('timeupdate', updateProgress);
        videoElement.addEventListener('loadedmetadata', () => {
            timeTotal.textContent = formatTime(videoElement.duration);
        });
        
        progressBar.addEventListener('click', (e) => {
            const rect = progressBar.getBoundingClientRect();
            const percent = (e.clientX - rect.left) / rect.width;
            videoElement.currentTime = percent * videoElement.duration;
        });
        
        // Volume
        volumeSlider.addEventListener('input', (e) => {
            videoElement.volume = e.target.value / 100;
            updateVolumeButton();
        });
        
        volumeBtn.addEventListener('click', () => {
            if (videoElement.volume > 0) {
                volumeSlider.value = 0;
                videoElement.volume = 0;
            } else {
                volumeSlider.value = 100;
                videoElement.volume = 1;
            }
            updateVolumeButton();
        });
        
        function updateVolumeButton() {
            if (videoElement.volume === 0) {
                volumeIcon.style.display = 'none';
                volumeMutedIcon.style.display = 'block';
            } else {
                volumeIcon.style.display = 'block';
                volumeMutedIcon.style.display = 'none';
            }
        }
        
        // Fullscreen
        function updateFullscreenButton() {
            const isFullscreen = document.fullscreenElement || 
                                document.webkitFullscreenElement || 
                                document.mozFullScreenElement || 
                                document.msFullscreenElement;
            
            if (isFullscreen) {
                fullscreenIcon.style.display = 'none';
                fullscreenExitIcon.style.display = 'block';
            } else {
                fullscreenIcon.style.display = 'block';
                fullscreenExitIcon.style.display = 'none';
            }
        }
        
        function enterFullscreen() {
            const element = videoElement; // Используем video элемент для полноэкранного режима
            
            if (element.requestFullscreen) {
                element.requestFullscreen().catch(err => {
                    console.log('Error attempting to enable fullscreen:', err);
                });
            } else if (element.webkitRequestFullscreen) {
                element.webkitRequestFullscreen();
            } else if (element.webkitEnterFullscreen) {
                // Для iOS
                element.webkitEnterFullscreen();
            } else if (element.mozRequestFullScreen) {
                element.mozRequestFullScreen();
            } else if (element.msRequestFullscreen) {
                element.msRequestFullscreen();
            }
        }
        
        function exitFullscreen() {
            if (document.exitFullscreen) {
                document.exitFullscreen();
            } else if (document.webkitExitFullscreen) {
                document.webkitExitFullscreen();
            } else if (document.mozCancelFullScreen) {
                document.mozCancelFullScreen();
            } else if (document.msExitFullscreen) {
                document.msExitFullscreen();
            }
        }
        
        fullscreenBtn.addEventListener('click', () => {
            const isFullscreen = document.fullscreenElement || 
                                document.webkitFullscreenElement || 
                                document.mozFullScreenElement || 
                                document.msFullscreenElement;
            
            if (!isFullscreen) {
                enterFullscreen();
            } else {
                exitFullscreen();
            }
        });
        
        // Слушаем события изменения полноэкранного режима
        document.addEventListener('fullscreenchange', updateFullscreenButton);
        document.addEventListener('webkitfullscreenchange', updateFullscreenButton);
        document.addEventListener('mozfullscreenchange', updateFullscreenButton);
        document.addEventListener('MSFullscreenChange', updateFullscreenButton);
        
        // Settings menu
        settingsBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            settingsMenu.style.display = settingsMenu.style.display === 'none' ? 'block' : 'none';
        });
        
        // Playback speed
        playbackSpeedSelect.addEventListener('change', (e) => {
            videoElement.playbackRate = parseFloat(e.target.value);
        });
        
        // Close settings menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!settingsMenu.contains(e.target) && !settingsBtn.contains(e.target)) {
                settingsMenu.style.display = 'none';
            }
        });
        
        // Auto-hide controls
        videoPlayer.addEventListener('mousemove', () => {
            showControls();
            clearTimeout(controlsTimeout);
            controlsTimeout = setTimeout(() => {
                hideControls();
            }, 3000);
        });
        
        function showControls() {
            if (!isControlsVisible) {
                document.getElementById('videoPlayerControls').classList.add('visible');
                isControlsVisible = true;
            }
        }
        
        function hideControls() {
            if (isPlaying && isControlsVisible) {
                document.getElementById('videoPlayerControls').classList.remove('visible');
                isControlsVisible = false;
            }
        }
        
        // Format time helper
        function formatTime(seconds) {
            if (isNaN(seconds)) return '0:00';
            const mins = Math.floor(seconds / 60);
            const secs = Math.floor(seconds % 60);
            return `${mins}:${secs.toString().padStart(2, '0')}`;
        }
    }
    
    // Detect mobile device
    function isMobileDevice() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
               (window.matchMedia && window.matchMedia('(max-width: 768px)').matches);
    }
    
    // Enter fullscreen for mobile devices
    function enterFullscreenForMobile() {
        if (!isMobileDevice() || !videoElement) return;
        
        // Для iOS используем webkitEnterFullscreen
        if (videoElement.webkitEnterFullscreen) {
            videoElement.webkitEnterFullscreen();
            return;
        }
        
        // Для других мобильных устройств используем стандартный API
        if (videoElement.requestFullscreen) {
            videoElement.requestFullscreen().catch(err => {
                console.log('Error entering fullscreen:', err);
            });
        } else if (videoElement.webkitRequestFullscreen) {
            videoElement.webkitRequestFullscreen();
        } else if (videoElement.mozRequestFullScreen) {
            videoElement.mozRequestFullScreen();
        } else if (videoElement.msRequestFullscreen) {
            videoElement.msRequestFullscreen();
        }
    }
    
    // Open video player
    function openVideoPlayer(videoSrc) {
        if (!videoPlayer) {
            initVideoPlayer();
        }
        
        videoElement = document.getElementById('videoPlayerVideo');
        videoElement.src = videoSrc;
        
        // На мобильных устройствах добавляем атрибуты для полноэкранного режима
        if (isMobileDevice()) {
            // Для iOS и других мобильных браузеров
            videoElement.setAttribute('playsinline', 'false');
            videoElement.setAttribute('webkit-playsinline', 'false');
            // Для WeChat и других китайских браузеров
            videoElement.setAttribute('x5-playsinline', 'false');
            videoElement.setAttribute('x5-video-player-type', 'h5');
            videoElement.setAttribute('x5-video-player-fullscreen', 'true');
            videoElement.setAttribute('x5-video-orientation', 'portraint');
            // Добавляем класс для мобильных устройств
            videoPlayer.classList.add('mobile-device');
        } else {
            videoElement.setAttribute('playsinline', 'true');
            videoPlayer.classList.remove('mobile-device');
        }
        
        videoPlayer.classList.add('active');
        document.body.style.overflow = 'hidden';
        
        // На мобильных устройствах сразу пытаемся войти в полноэкранный режим
        if (isMobileDevice()) {
            // Небольшая задержка для загрузки видео
            setTimeout(() => {
                enterFullscreenForMobile();
            }, 100);
        }
        
        // Auto-play (optional - may be blocked by browser)
        const playPromise = videoElement.play();
        
        if (playPromise !== undefined) {
            playPromise.then(() => {
                // На мобильных устройствах после начала воспроизведения еще раз пытаемся войти в полноэкранный режим
                if (isMobileDevice()) {
                    setTimeout(() => {
                        enterFullscreenForMobile();
                    }, 200);
                }
            }).catch(err => {
                console.log('Autoplay prevented:', err);
                // Даже если autoplay заблокирован, на мобильных пытаемся войти в полноэкранный режим
                if (isMobileDevice()) {
                    setTimeout(() => {
                        enterFullscreenForMobile();
                    }, 300);
                }
            });
        }
    }
    
    // Attach event listeners to video play buttons
    function attachVideoButtons() {
        // Brandup gallery play buttons - handle clicks on gallery items
        const brandupGalleryItems = document.querySelectorAll('.brandup-gallery-item');
        brandupGalleryItems.forEach(item => {
            item.addEventListener('click', (e) => {
                // Don't trigger if clicking on a link or button inside
                if (e.target.closest('a, button')) {
                    return;
                }
                
                e.preventDefault();
                e.stopPropagation();
                
                // Get video source from data attribute or use placeholder
                const videoSrc = item.dataset.videoSrc || 
                                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
                
                openVideoPlayer(videoSrc);
            });
        });
        
        // Portfolio video buttons (if any)
        const portfolioPlayButtons = document.querySelectorAll('.portfolio-item[data-video-src], .portfolio-play');
        portfolioPlayButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                const videoSrc = button.dataset.videoSrc || button.closest('.portfolio-item')?.dataset.videoSrc;
                if (videoSrc) {
                    e.preventDefault();
                    e.stopPropagation();
                    openVideoPlayer(videoSrc);
                }
            });
        });
        
        // Services section images
        const servicesItems = document.querySelectorAll('.service-item, .service-item img');
        servicesItems.forEach(item => {
            item.addEventListener('click', (e) => {
                // Don't trigger if clicking on a link or button inside
                if (e.target.closest('a, button')) {
                    return;
                }
                
                e.preventDefault();
                e.stopPropagation();
                
                // Get video source from data attribute or use placeholder
                const serviceItem = item.closest('.service-item') || item.parentElement;
                const videoSrc = serviceItem?.dataset.videoSrc || 
                                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
                
                openVideoPlayer(videoSrc);
            });
        });
        
        // Generic video play buttons with data-video-src attribute
        const genericPlayButtons = document.querySelectorAll('[data-video-src]');
        genericPlayButtons.forEach(button => {
            if (!button.closest('.brandup-gallery-item') && 
                !button.closest('.portfolio-item') && 
                !button.closest('.service-item')) {
                button.addEventListener('click', (e) => {
                    const videoSrc = button.dataset.videoSrc;
                    if (videoSrc) {
                        e.preventDefault();
                        e.stopPropagation();
                        openVideoPlayer(videoSrc);
                    }
                });
            }
        });
    }
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', attachVideoButtons);
    } else {
        attachVideoButtons();
    }
    
    // Export function for external use
    window.openVideoPlayer = openVideoPlayer;
})();
