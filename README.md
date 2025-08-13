# KOMATIPALLY PRODUCTIONS × SAR ENTERTAINMENTS — Website

A lightweight, static, cinematic website for a film production house.

## Quick start

- Open `index.html` in your browser.
- Or serve the folder locally:

```bash
# Python 3
python3 -m http.server 5173
# Then open http://localhost:5173
```

## Structure

- `index.html`: Main page
- `styles.css`: Theme and layout (dark mode, gold accents)
- `scripts.js`: Navigation, scroll reveal, contact form mailto

## Customize

- Update brand text in `index.html` (`.brand-name`, `<title>`, footer)
- Replace images and YouTube links in `#slate` and `#trailers`
- Update contact email in `index.html` and `scripts.js`
- Add real social links in the JSON-LD and Contact section

## Notes

- All media are loaded from public CDNs. Replace with your own assets for production.
- The contact form uses a `mailto:` fallback (no server required). For production forms, connect a backend or a service like Formspree.