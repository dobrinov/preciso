# Open Graph / social share tags — design

## Goal

Add Open Graph + Twitter-card meta tags so shared links to the storefront render a
branded card: the Preciso logo image plus text drawn from the (editable) home page.

## Background

The storefront layout (`app/views/layouts/application.html.erb`) has a `<head>` with
`<title>` (via `content_for(:title)`), viewport/csrf/csp meta, and `<%= yield :head %>`.
No OG tags today. The editable home-page text lives in the `HomePage` singleton,
exposed in views via the memoized `home_page` helper (already used by the footer).

## Approach

A new partial `app/views/shared/_meta_tags.html.erb`, rendered in the storefront
layout `<head>` (admin layout untouched — admin pages aren't shared). It emits OG +
Twitter tags site-wide, with text from `home_page` and the brand image.

### Values

- `og:type` = "website"
- `og:site_name` = "Preciso"
- `og:title` = hero title flattened to one line + accent, e.g. "Quiet objects for daily rituals"
  (`home_page.hero_title.split("\n").join(" ")` + `home_page.hero_accent`, blanks dropped)
- `og:description` = `home_page.hero_subtext`
- `og:url` = `request.original_url` (absolute, current page)
- `og:image` = absolute URL of the static asset: `request.base_url + image_path("og-image.png")`
  (absolute regardless of asset_host; scraper fetches from the same host it scrapes)
- `og:image:width` = 1050, `og:image:height` = 600, `og:image:alt` = "Preciso"
- `twitter:card` = "summary_large_image", `twitter:title`/`twitter:description`/`twitter:image`
  mirror the OG values
- `<meta name="description">` = same description (SEO bonus)

All values are interpolated into HTML attributes via `<%= %>`, so they are
HTML-escaped (no XSS even though `home_page` text is user-editable).

### Image asset

The provided logo (1050×600 PNG, ~28 KB) is copied to
`app/assets/images/og-image.png` and served by Propshaft (digested URL).

## Out of scope

- Per-page OG (e.g. a product's own photo/price/title when sharing a product link) —
  a possible follow-up; this change is one site-wide brand card.
- Editing the OG image/text from the admin (text already follows the editable hero;
  the image is a static brand asset).
- The admin layout.

## Verification

No automated suite. Verify with `bin/rubocop` (no Ruby changed, but run anyway) and:

1. The home page `<head>` contains the OG/Twitter tags with the homepage hero text
   and an absolute `og:image` URL ending in `/assets/og-image-<digest>.png`.
2. A non-home storefront page also carries the tags (site-wide), with `og:url`
   reflecting that page.
3. `og:title` has the hero title on one line (newline flattened) + accent.
4. Editing the hero text changes `og:title`/`og:description` (shared `home_page`).
5. On production: the asset URL is reachable (200) and the tags are present.
