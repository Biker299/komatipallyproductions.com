# Deploy

## GitHub Pages (recommended)

1) Create a new GitHub repository (public)
2) Add it as a remote and push the code:

```bash
git init -b main
git add .
git commit -m "Initial site and Pages workflow"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

3) The included workflow `.github/workflows/deploy.yml` will build and publish automatically. In a minute, check the repo's Environments → github-pages for the live URL, or Settings → Pages.

## Custom domain

- Add a CNAME record pointing your domain to `<your-username>.github.io`
- In repo Settings → Pages, set your custom domain

## Alternatives

- Netlify: drag-and-drop the folder, or use CLI (`netlify deploy --prod --dir .`)
- Vercel: import the repo, or use CLI (`vercel --yes --prod`)
- Cloudflare Pages: connect the repo, or `wrangler pages deploy .`