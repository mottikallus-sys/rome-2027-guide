# Road Trip 2027 — Rome guide

The homepage displays **ROAD TRIP 2027**. The city remains Rome and dates remain Dec 31, 2026–Jan 6, 2027.

## Publish on GitHub Pages
1. Extract the ZIP. Upload **all files and folders**, including `.github`, `assets`, and `scripts`, to the **root** of your repository.
2. Go to **Settings → Pages → Build and deployment** and set **Source: GitHub Actions**. The `deploy-pages.yml` workflow publishes the site on push to `main`.
3. Under **Actions** check the deployment result; the published URL will be shown in Pages settings.
4. Optional event feed: create the Actions secret `TICKETMASTER_API_KEY`. The daily `update-events.yml` checks Ticketmaster for listings during your dates. Listings will NOT be comprehensive; curated leads remain.

## What the YAML files do
- `.github/workflows/deploy-pages.yml`: publishes the site to GitHub Pages.
- `.github/workflows/update-events.yml`: refreshes partial event listings when an API key is set.
- `site-config.yml`: documents names, languages, dates and live widgets. The current website does **not** read this YAML dynamically.
- `image-audit.yml`: records which images are **illustrations** (not real verified venue photography).

Current weather and exchange rates refresh in the browser only when online; values can be missing if a third-party service is unavailable. Transport times are estimates, and kosher supervision/events require reconfirmation. Your exact Airbnb address is included in a website that may be public.
