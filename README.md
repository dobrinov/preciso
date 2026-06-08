# Preciso — Handmade Porcelain by Bianna Taynova

A porcelain studio storefront with a simple (no-online-payment) checkout and a
full studio admin panel, implemented in **Ruby on Rails 8 + SQLite**. The design
is a faithful, pixel-accurate port of the Tonda-inspired "Preciso" prototype
(Cormorant Garamond serif headings, Jost body, a white canvas, and a single clay
taupe accent). The prototype's browser-only data is now backed by a real
database.

## What's here

**Storefront**
- Home — editorial hero, a featured set, browse-by-category tiles, a maker strip, latest pieces
- Category shop pages, a Sets index, and product / set detail pages (sets list their contents and the "bought separately" price)
- Cart drawer → simple checkout (name, email, phone + optional note — no payment) → order confirmation with an order number
- About page with the studio story

**Admin** (`/admin`, password: `studio`)
- **Dashboard** — revenue, order counts, recent orders, best sellers
- **Analytics** — on-device-style web analytics (visitors, page views, add-to-carts, orders, a traffic chart, top pages/pieces, an activity feed)
- **Orders** — filter by status, open an order to see contact details, move it New → Preparing → Fulfilled → Cancelled
- **Categories** — add / edit / delete categories (name, blurb, placeholder tone); slugs track the name so shop URLs stay meaningful
- **Products** — add / edit / delete pieces per category, each with **multiple photos** (the first is the cover; drag to drop, mark any to remove)
- **Sets** — a builder: click pieces to combine them, price the set, see the saving vs. buying separately
- **About** — edit the studio story live

Customer orders flow straight into Orders and Analytics; admin edits update the storefront immediately. Admin pageviews are never counted in analytics.

## Stack

- Ruby 4.0 / Rails 8.1, SQLite
- Hotwire (Turbo + Stimulus) over the importmap pipeline; Propshaft assets
- Active Storage (local disk) for product / set photos
- No CSS framework — the design system is a hand-written stylesheet in `app/assets/stylesheets/application.css`

## Running it

```bash
bin/rails db:setup   # create, migrate, and seed the catalogue + demo data
bin/rails server
```

Then open http://localhost:3000 — and the admin at http://localhost:3000/admin (password `studio`, also reachable via the storefront footer "Studio login").

To reset to a fresh seeded state at any time:

```bash
bin/rails db:reset
```

## Notes

- Products and sets ship with elegant labeled placeholders; upload real photos per item in the admin and they slot straight in. Products support several photos with a thumbnail gallery on the product page; sets keep a single photo.
- Photo uploads use Active Storage on local disk and are rendered as-is (no on-the-fly variants), so no `libvips`/`imagemagick` is required to run the app.
- The cart lives in the session; the catalogue, sets, orders, About text, and analytics live in SQLite.
