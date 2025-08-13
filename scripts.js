// Mobile navigation toggle
const navToggleButton = document.querySelector('[data-nav-toggle]');
const navMenu = document.querySelector('[data-nav-menu]');
if (navToggleButton && navMenu) {
  navToggleButton.addEventListener('click', () => {
    const isOpen = navMenu.classList.toggle('is-open');
    navToggleButton.setAttribute('aria-expanded', String(isOpen));
  });
}

// Sticky header subtle shadow on scroll
const header = document.querySelector('[data-header]');
let lastScrollY = 0;
window.addEventListener('scroll', () => {
  const y = window.scrollY;
  if (!header) return;
  header.style.boxShadow = y > 8 ? '0 6px 20px rgba(0,0,0,.25)' : 'none';
  lastScrollY = y;
});

// Reveal on scroll
const revealables = document.querySelectorAll('.reveal');
const io = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) entry.target.classList.add('is-visible');
    });
  },
  { root: null, rootMargin: '0px 0px -10% 0px', threshold: 0.1 }
);
revealables.forEach((el) => io.observe(el));

// Update year
const yearEl = document.querySelector('[data-year]');
if (yearEl) yearEl.textContent = String(new Date().getFullYear());

// Contact form -> mailto fall back
const contactForm = document.querySelector('[data-contact-form]');
if (contactForm) {
  contactForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const form = e.currentTarget;
    const name = form.querySelector('#name')?.value?.trim() ?? '';
    const email = form.querySelector('#email')?.value?.trim() ?? '';
    const subject = form.querySelector('#subject')?.value?.trim() ?? 'Inquiry';
    const message = form.querySelector('#message')?.value?.trim() ?? '';

    const body = encodeURIComponent(`Name: ${name}\nEmail: ${email}\n\n${message}`);
    const mailto = `mailto:contact@komatipally-sar.com?subject=${encodeURIComponent(subject)}&body=${body}`;

    // Try opening the user's mail client
    window.location.href = mailto;

    // Provide UX feedback
    const button = form.querySelector('button[type="submit"]');
    if (button) {
      const original = button.textContent;
      button.textContent = 'Opening mail client…';
      button.disabled = true;
      setTimeout(() => {
        button.textContent = original;
        button.disabled = false;
      }, 2000);
    }
  });
}