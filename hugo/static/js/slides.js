document.addEventListener('DOMContentLoaded', () => {
  const slides = document.querySelectorAll('.slide');
  const currentSlideSpan = document.getElementById('current-slide');
  const totalSlidesSpan = document.getElementById('total-slides');
  let currentIndex = 0;

  function pad(num) {
    return num.toString().padStart(2, '0');
  }

  function animateStats(slide) {
    const statNumbers = slide.querySelectorAll('.stat-number');
    statNumbers.forEach(stat => {
      const targetStr = stat.getAttribute('data-target');
      if (!targetStr) return;
      
      const target = parseFloat(targetStr);
      if (isNaN(target)) return;

      const formatComma = stat.getAttribute('data-raw').includes(',');
      const duration = 1200; // ms
      const startTime = performance.now();
      
      function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // easeOutQuart
        const easeOut = 1 - Math.pow(1 - progress, 4);
        const val = Math.floor(easeOut * target);
        
        stat.textContent = formatComma ? val.toLocaleString('en-US') : val;
        
        if (progress < 1) {
          requestAnimationFrame(update);
        } else {
          stat.textContent = stat.getAttribute('data-raw');
        }
      }
      
      // Start from 0 instantly
      stat.textContent = "0";
      // Small delay so it animates right as the slide wave animation brings it in
      setTimeout(() => {
        requestAnimationFrame(update);
      }, 150);
    });
  }

  function updateSlide(newIndex) {
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= slides.length) newIndex = slides.length - 1;

    // Remove active class from all
    slides.forEach(slide => {
      slide.classList.remove('active');
    });

    // Add active class to current
    slides[newIndex].classList.add('active');
    
    // Animate stats if moving forward
    if (newIndex !== currentIndex) {
      animateStats(slides[newIndex]);
    }
    
    // Update counter (1-indexed) with zero padding
    currentSlideSpan.textContent = pad(newIndex + 1);
    totalSlidesSpan.textContent = pad(slides.length);
    
    // Update Progress Bar
    const progressPercent = slides.length > 1 ? (newIndex / (slides.length - 1)) * 100 : 100;
    document.getElementById('progress-fill').style.width = `${progressPercent}%`;

    // Update hash silently if it's not matching
    const expectedHash = `#${newIndex}`;
    if (window.location.hash !== expectedHash) {
      history.replaceState(null, null, expectedHash);
    }

    // Handle steps reset or reveal based on direction
    const stepsInNewSlide = slides[newIndex].querySelectorAll('.step-container > *');
    if (newIndex > currentIndex) {
      // Moving Forward: Hide all steps instantly without transition so they don't flash
      stepsInNewSlide.forEach(step => {
        step.style.transition = 'none';
        step.classList.remove('revealed');
        void step.offsetWidth; // Force reflow
        step.style.transition = '';
      });
    } else if (newIndex < currentIndex) {
      // Moving Backward: Reveal all steps immediately so the slide looks "complete"
      stepsInNewSlide.forEach(step => {
        step.style.transition = 'none';
        step.classList.add('revealed');
        void step.offsetWidth; // Force reflow
        step.style.transition = '';
      });
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
    animateStats(slides[index]);
  }

  // Listen for hash changes (e.g. user manually edits URL or back/forward buttons)
  window.addEventListener('hashchange', () => {
    initFromHash();
  });

  // Keyboard controls
  window.addEventListener('keydown', (e) => {
    if (['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;

    if (e.key === 'ArrowRight') {
      e.preventDefault();
      updateSlide(currentIndex + 1); // Strictly pages right
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      updateSlide(currentIndex - 1); // Strictly pages left
    } else if (e.key === 'f' || e.key === 'F') {
      e.preventDefault();
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(err => {
          console.log(`Error attempting to enable fullscreen: ${err.message}`);
        });
      } else {
        if (document.exitFullscreen) {
          document.exitFullscreen();
        }
      }
    } else if (e.key === ' ') {
      e.preventDefault();
      
      // Look for hidden steps in the CURRENT active slide
      const activeSlide = slides[currentIndex];
      if (activeSlide) {
        const hiddenSteps = Array.from(activeSlide.querySelectorAll('.step-container > *:not(.revealed)'));
        if (hiddenSteps.length > 0) {
          // If there are unrevealed steps, reveal the next one and STOP here
          hiddenSteps[0].classList.add('revealed');
          return;
        }
      }
      
      // If no unrevealed steps exist (or the slide has no steps), act like right arrow
      updateSlide(currentIndex + 1);
    }
  });

  // Initialize
  initFromHash();
});