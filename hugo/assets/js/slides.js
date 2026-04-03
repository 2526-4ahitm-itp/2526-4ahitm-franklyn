/**
 * Slides - Minimal presentation navigation
 */
(function() {
  'use strict';

  const presentation = document.querySelector('.presentation');
  const slides = Array.from(document.querySelectorAll('.slide'));
  const total = slides.length;
  const counter = document.querySelector('.slide-counter .current');
  const progress = document.querySelector('.progress-fill');

  let current = 0;

  // Format number with leading zero
  function formatNum(n) {
    return n < 10 ? '0' + n : String(n);
  }

  // Initialize from URL hash
  function initFromHash() {
    const hash = window.location.hash;
    if (hash) {
      const match = hash.match(/^#slide-(\d+)$/);
      if (match) {
        const slideNum = parseInt(match[1], 10) - 1;
        if (slideNum >= 0 && slideNum < total) {
          current = slideNum;
        }
      }
    }
    goToSlide(current, false);
  }

  // Navigate to a specific slide
  function goToSlide(index, animate = true) {
    if (index < 0 || index >= total) return;

    const oldSlide = slides[current];
    const newSlide = slides[index];

    if (oldSlide !== newSlide) {
      oldSlide.classList.remove('active');
      newSlide.classList.add('active');
      
      // Update background based on new slide's bg class
      const bgElement = document.querySelector('.slide-bg');
      if (bgElement) {
        let bgClass = '';
        for (const className of newSlide.classList) {
          if (className.startsWith('bg-gradient-')) {
            bgClass = className;
            break;
          }
        }
        // Update data attribute for CSS targeting
        bgElement.setAttribute('data-bg', bgClass);
      }
    }

    current = index;

    // Update URL hash
    history.replaceState(null, '', `#slide-${current + 1}`);

    // Update counter with leading zero format
    if (counter) {
      counter.textContent = formatNum(current + 1);
    }

    // Update progress bar
    if (progress) {
      const percent = total > 1 ? (current / (total - 1)) * 100 : 100;
      progress.style.width = `${percent}%`;
    }
  }

  function nextSlide() {
    if (current < total - 1) {
      goToSlide(current + 1);
    }
  }

  function prevSlide() {
    if (current > 0) {
      goToSlide(current - 1);
    }
  }

  // Keyboard navigation
  document.addEventListener('keydown', function(e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
      return;
    }

    switch(e.key) {
      case 'ArrowRight':
      case 'ArrowDown':
      case ' ':
      case 'PageDown':
        e.preventDefault();
        nextSlide();
        break;
      case 'ArrowLeft':
      case 'ArrowUp':
      case 'PageUp':
        e.preventDefault();
        prevSlide();
        break;
      case 'Home':
        e.preventDefault();
        goToSlide(0);
        break;
      case 'End':
        e.preventDefault();
        goToSlide(total - 1);
        break;
      case 'f':
        e.preventDefault();
        toggleFullscreen();
        break;
    }
  });

  // Touch/swipe support
  let touchStartX = 0;

  presentation.addEventListener('touchstart', function(e) {
    touchStartX = e.changedTouches[0].screenX;
  }, { passive: true });

  presentation.addEventListener('touchend', function(e) {
    const touchEndX = e.changedTouches[0].screenX;
    const diff = touchStartX - touchEndX;
    
    if (Math.abs(diff) > 50) {
      if (diff > 0) {
        nextSlide();
      } else {
        prevSlide();
      }
    }
  }, { passive: true });

  // Fullscreen toggle
  function toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    } else {
      document.exitFullscreen().catch(() => {});
    }
  }

  // Handle hash changes
  window.addEventListener('hashchange', initFromHash);

  // Initialize
  initFromHash();
})();
