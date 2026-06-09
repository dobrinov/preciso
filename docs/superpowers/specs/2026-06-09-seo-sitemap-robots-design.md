# SEO: sitemap.xml, robots.txt, and meta/structured-data tags

## Goal

Improve discoverability and rich results: serve a current `sitemap.xml`, a proper
`robots.txt`, per-page titles + canonical tags, and schema.org JSON-LD — all anchored
to a single canonical domain so apex / `www` / `fly.dev` aren't treated as duplicates.

## Canonical host

`https://www.precisodesign.com` is the canonical domain. Add to `ApplicationHelper`:

```ruby
CANONICAL_HOST = "https://www.precisodesign.com".freeze

def canonical_url(path = nil)
  "#{CANONICAL_HOST}#{path || request.path}"
end
```

`absolute_url` and `og_image_url` switch from `request.base_url` to `CANONICAL_HOST`,
so `og:url`, `og:image`, `<link rel="canonical">`, and the sitemap all use the canonical
host regardless of which host served the request. (Browsing via `fly.dev` therefore
advertises the `www.precisodesign.com` URLs — intended.)

## sitemap.xml

- Route: `get "sitemap.xml", to: "sitemaps#show", defaults: { format: "xml" }`.
- `SitemapsController < ApplicationController` (`#show`) gathers records:
  `@categories = Category.all`, `@products = Product.order(:id)`,
  `@sets = ProductSet.order(:id)`, `@collections = Collection.all`,
  `@campaigns = Campaign.active`. Does **not** call `track`.
- `app/views/sitemaps/show.xml.erb` renders a `<urlset>` with one `<url>` per:
  - static: `canonical_url("/")`, `canonical_url(about_path)`, `canonical_url(sets_path)`,
    `canonical_url(collections_path)` (no `<lastmod>`)
  - each category → `canonical_url(shop_category_path(c.slug))`
  - each product → `canonical_url(product_path(p))`
  - each set → `canonical_url(product_set_path(s))`
  - each collection → `canonical_url(collection_path(c))`
  - each active campaign → `canonical_url(campaign_path(c))`
  - records include `<lastmod><%= record.updated_at.iso8601 %></lastmod>`
- Excludes cart, checkout, admin, login. Response content type `application/xml`
  (use `<loc>` values escaped — ERB `<%= %>` escapes by default).

## robots.txt

Replace `public/robots.txt` with:

```
User-agent: *
Disallow: /admin
Disallow: /cart
Disallow: /checkout

Sitemap: https://www.precisodesign.com/sitemap.xml
```

The secret login path is intentionally omitted (robots.txt is public).

## Meta tags

In `app/views/layouts/application.html.erb`, replace the `<title>`:

```erb
<title><%= content_for(:title).presence || (@meta_title.present? ? "#{@meta_title} · Preciso" : "Preciso — Handmade Porcelain by Bianna Taynova") %></title>
```

So pages that set `content_for(:title)` keep it; pages that set `@meta_title`
(product/set/category/collection/campaign/about — already set for OG) get
`"<name> · Preciso"`; the home page keeps the default.

In `app/views/shared/_meta_tags.html.erb` add:

```erb
<link rel="canonical" href="<%= canonical_url %>">
<% if @noindex %><meta name="robots" content="noindex"><% end %>
```

Change `og:url` to `<%= canonical_url %>`. `CheckoutController` sets `@noindex = true`
in `new` and `confirmation`.

## JSON-LD structured data

New partial `app/views/shared/_structured_data.html.erb`, rendered in the layout head.
Emits, as `<script type="application/ld+json"><%= raw data.to_json %></script>`
(Rails JSON escapes `<`/`>`/`&` to `\u…`, so it can't break out of the script):

- **Organization** (always):
  `{ "@context": "https://schema.org", "@type": "Organization", "name": "Preciso",
     "url": CANONICAL_HOST, "logo": absolute_url(image_path("og-image.png")) }`
- **Product** (when `@meta_type == "product"`, i.e. product & set pages):
  `{ "@context": "https://schema.org", "@type": "Product", "name": @meta_title,
     "image": og_image_url(@meta_image), "description": @meta_description,
     "offers": { "@type": "Offer", "price": @meta_price.to_s, "priceCurrency": "EUR",
     "availability": "https://schema.org/InStock", "url": canonical_url } }`

A helper `structured_data` (ApplicationHelper) returns the array of hashes; the partial
iterates and renders one script tag each.

## Files

- New: `app/controllers/sitemaps_controller.rb`, `app/views/sitemaps/show.xml.erb`,
  `app/views/shared/_structured_data.html.erb`.
- Modify: `config/routes.rb`, `public/robots.txt`, `app/helpers/application_helper.rb`,
  `app/views/shared/_meta_tags.html.erb`, `app/views/layouts/application.html.erb`,
  `app/controllers/checkout_controller.rb`.

## Out of scope

- `sitemap_generator` gem (live route is simpler and always current).
- LocalBusiness / BreadcrumbList / hreflang schema, sitemap pagination, image sitemaps.
- Admin pages (behind auth, not crawlable).

## Verification

No automated suite. Verify with `bin/rubocop` and an `ActionDispatch::Integration::Session`
(test env):

1. `GET /sitemap.xml` → 200, `application/xml`, valid `<urlset>` with canonical-host
   `<loc>`s for home/about/indexes and each category/product/set/collection/active
   campaign; no cart/checkout/admin/login URLs.
2. `GET /robots.txt` → contains the Disallow rules + the `Sitemap:` line; no login path.
3. A product page: `<title>` is "<name> · Preciso"; `<link rel="canonical">` and `og:url`
   use `www.precisodesign.com`; a Product JSON-LD block with price/currency/availability;
   an Organization block.
4. The home page: default title, canonical to `https://www.precisodesign.com/`,
   Organization JSON-LD only (no Product).
5. A checkout page: `<meta name="robots" content="noindex">` present.
6. JSON-LD parses as valid JSON (no script-breakout).
