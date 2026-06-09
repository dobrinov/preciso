# Editable home-page text — design

## Goal

Let the studio edit the home page's hardcoded prose from the admin: the **hero**
(eyebrow, title, italic accent, subtext), the **maker** section (eyebrow, heading,
paragraph), and the site-wide **footer blurb**. Mirrors the existing `About`
singleton + admin editor.

## Background

Today these texts live hardcoded in `app/views/home/index.html.erb` (hero block,
maker block) and `app/views/shared/_footer.html.erb` (footer blurb). The hero title
carries styling: a line break (`<br>`) and an italic clay-coloured accent on the
last word(s) — `Quiet objects<br>for daily<span class="italic clay-text"> rituals</span>`.

The codebase already has an editable singleton, `About` (`About.instance`
first-or-creates a seeded row), with `Admin::AboutController` (edit/update reading
top-level params) and an admin nav item "About page". This feature follows that
pattern exactly.

## Data model — `HomePage` singleton

New model `HomePage` with `self.instance` (first-or-creates seeded with the current,
wheel-free copy). Fields:

- `hero_eyebrow` (string)  — "Handmade Porcelain · Bianna Taynova"
- `hero_title` (text)      — "Quiet objects\nfor daily" (newlines render as `<br>`)
- `hero_accent` (string)   — "rituals" (italic clay tail; optional)
- `hero_subtext` (text)    — "Hand-built bowls, cups and vases in fine white porcelain — finished by hand, made in small batches, sold as they leave the kiln."
- `maker_eyebrow` (string) — "The maker"
- `maker_title` (string)   — "Made by one pair of hands"
- `maker_text` (text)      — "Each piece begins as fine porcelain and is built entirely by hand — shaped, refined, glazed and fired. Small differences are the record of how it was made."
- `footer_blurb` (text)    — "Handmade porcelain by Bianna Taynova. Shaped, trimmed and glazed by hand in small batches."

One migration creates `home_pages`. No data lost — defaults reproduce today's copy.

## Access — `home_page` helper

The footer partial renders on every page (in the layout), so it can't rely on a
controller setting `@home`. Add a memoized helper in `ApplicationHelper`:

```ruby
def home_page
  @_home_page ||= HomePage.instance
end
```

Both `home/index.html.erb` and `_footer.html.erb` use `home_page`, so it's a single
query per request.

## Rendering

`home/index.html.erb` hero:
```erb
<div class="eyebrow clay"><%= home_page.hero_eyebrow %></div>
<h1 class="display hero-title"><%= safe_join(home_page.hero_title.split("\n"), tag.br) %><% if home_page.hero_accent.present? %> <span class="italic clay-text"><%= home_page.hero_accent %></span><% end %></h1>
<p class="hero-lede"><%= home_page.hero_subtext %></p>
```
`safe_join` + `tag.br` renders line breaks while HTML-escaping each line (no XSS);
the accent is escaped inside its span; empty accent → no span.

`home/index.html.erb` maker:
```erb
<div class="eyebrow clay"><%= home_page.maker_eyebrow %></div>
<h2 class="display maker-title"><%= home_page.maker_title %></h2>
<p class="maker-text"><%= home_page.maker_text %></p>
```

`_footer.html.erb`:
```erb
<p class="foot-blurb"><%= home_page.footer_blurb %></p>
```

The maker portrait image stays `@about.image` (unchanged); only its text is editable.
The hero CTAs and "Read the studio story" link stay hardcoded.

## Admin

- Route: `resource :home_page, only: [ :edit, :update ], controller: "home_page"`
  (under the existing `namespace :admin`).
- `Admin::HomePageController` (`edit` loads `HomePage.instance`; `update` reads
  top-level params — `params[:hero_eyebrow]` etc. — and saves, then redirects with a
  `notice`), mirroring `Admin::AboutController`.
- `app/views/admin/home_page/edit.html.erb`: header ("Home page", a "View page"
  link to `root_path`, a Save button), flash notice, then three field groups —
  Hero (eyebrow, title as a textarea so line breaks show, accent with a hint that
  it renders italic/clay, subtext textarea), Maker (eyebrow, title, text textarea),
  Footer (blurb textarea). Styled like the About editor (`.field`, `.input`,
  `.card-pad`, `.admin-pad`).
- Sidebar nav (`admin/shared/_sidebar.html.erb`): add
  `["home", "Home page", :doc, edit_admin_home_page_path]` to the `nav` array and
  `when "home_page" then "home"` to the `active` case (the controller's
  `controller_name` is `"home_page"`).

## Out of scope

- Hero CTA buttons, the "Read the studio story" link, the featured-set card.
- Category tiles / products / sets (already editable elsewhere).
- The maker portrait image (stays the About image).
- Rich text / HTML input — fields are plain text; only the hero title's newlines
  and the accent get special rendering.

## Verification

No automated suite (per `CLAUDE.md`). Verify with `bin/rubocop` and:

1. After migrate, the home page renders byte-for-byte the same as before (defaults
   reproduce current copy; hero line break + italic accent intact).
2. The footer blurb renders from the singleton on home and a non-home page.
3. Admin → Home page editor renders all fields populated.
4. Editing each field (via an `ActionDispatch::Integration::Session` in the test
   env) updates the home page and footer accordingly; clearing the accent drops the
   span.
