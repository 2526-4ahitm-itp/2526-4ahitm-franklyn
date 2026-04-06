document.addEventListener('DOMContentLoaded', () => {
  const slides = document.querySelectorAll('.slide');
  const currentSlideSpan = document.getElementById('current-slide');
  const totalSlidesSpan = document.getElementById('total-slides');
  let currentIndex = 0;

  function updateSlide(newIndex) {
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= slides.length) newIndex = slides.length - 1;

    // Remove active class from all
    slides.forEach(slide => {
      slide.classList.remove('active');
    });

    // Add active class to current
    slides[newIndex].classList.add('active');
    
    // Update counter (1-indexed)
    currentSlideSpan.textContent = newIndex + 1;
    
    // Update hash silently if it's not matching
    const expectedHash = `#${newIndex}`;
    if (window.location.hash !== expectedHash) {
      history.replaceState(null, null, expectedHash);
    }

    currentIndex = newIndex;
  }

  // Handle URL hash on load
  function initFromHash() {
    const hash = window.location.hash;
    let index = 0;
    if (hash && hash.length > 1) {
      const parsed = parseInt(hash.substring(1), 10);
      if (!isNaN(parsed) && parsed >= 0 && parsed < slides.length) {
        index = parsed;
      }
    }
    updateSlide(index);
  }

  // Listen for hash changes (e.g. user manually edits URL or back/forward buttons)
  window.addEventListener('hashchange', () => {
    initFromHash();
  });

  // Keyboard controls
  window.addEventListener('keydown', (e) => {
    // Ignore if typing in input/textarea (though rare in presentations)
    if (['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;

    if (e.key === 'ArrowRight' || e.key === ' ') {
      e.preventDefault();
      updateSlide(currentIndex + 1);
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      updateSlide(currentIndex - 1);
    }
  });

  // Initialize
  initFromHash();
});