# Configurable featured item — design

## Goal

Replace the hardcoded home-page featured slot (always the first `ProductSet`) with
an admin-chosen featured item that can be a **product, set, or collection** — and
when a **campaign is active, the campaign is featured automatically**, overriding the
pick. Configured from the existing admin → Home page editor.

## Background

`HomeController#index` sets `@hero_set = ProductSet.order(:id).first`. The hero
renders a "hero-feature" card (`app/views/home/index.html.erb`) linking to the set,
showing `media_for(@hero_set, kind: "set", ratio: "125%")`, an eyebrow ("Featured
set"), and the name. A separate campaign banner strip is rendered just below the hero
(`<%= render "shared/campaign_banner" %>`).

Editable home content already lives in the `HomePage` singleton (`home_page` helper).
`Campaign` enforces a single active campaign (`Campaign.active.first` is unambiguous).
`cover_attachment` (media_helper) resolves a record's image for `primary_image`
(Product) and `image` (ProductSet/Category), but not Collection `cover` or Campaign
`banner`.

## Resolution priority

`HomeController#index` computes `@featured` as the first of:

1. `Campaign.active.first` — an active campaign is always featured.
2. `HomePage.instance.featured_record` — the admin-picked product/set/collection.
3. `ProductSet.order(:id).first` — legacy fallback, so the slot is never empty.

`@featured` may be `nil` only if there are no sets at all (then the card is omitted,
as today).

## Data model

Add to `home_pages`:
- `featured_kind` — string, nullable (`"product"` | `"set"` | `"collection"`)
- `featured_id` — integer, nullable

`HomePage#featured_record` resolves them, returning `nil` if unset or the record was
deleted:

```ruby
def featured_record
  case featured_kind
  when "product"    then Product.find_by(id: featured_id)
  when "set"        then ProductSet.find_by(id: featured_id)
  when "collection" then Collection.find_by(id: featured_id)
  end
end
```

## Rendering

A `featured_meta(record)` helper maps the record's class to its presentation:

| Class        | eyebrow                | path                      | image           |
|--------------|------------------------|---------------------------|-----------------|
| Campaign     | "Featured offer"       | `campaign_path`           | `banner`        |
| ProductSet   | "Featured set"         | `product_set_path`        | `image`         |
| Collection   | "Featured collection"  | `collection_path`         | `cover`         |
| Product      | "Featured piece"       | `product_path`            | `primary_image` |

`cover_attachment` is extended to also resolve `cover` (Collection) and `banner`
(Campaign), so the shared image renderer works for every type. The hero-feature card
markup moves into a `shared/_featured` partial rendered with `record: @featured`; it
uses `featured_meta` for the eyebrow/link and renders the image in the existing
`ratio-box img-frame` (125%) with a `placeholder` fallback (tone from `record.tone`
when available, else a neutral default).

The home view renders the featured card only when `@featured` is present.

## Campaign banner

Remove the campaign banner strip from the **home page** only (delete the
`<%= render "shared/campaign_banner" %>` line in `home/index.html.erb`), since the
campaign now appears in the featured card. The partial and any other usages are left
intact.

## Admin

In the Home page editor (`admin/home_page/edit.html.erb`), add a **Featured item**
control: a single grouped `<select name="featured">` with optgroups Products / Sets /
Collections, each option value `"#{kind}:#{id}"`, plus a "None (use the default)"
option (empty value). Selected option reflects the current `featured_kind:featured_id`.
A hint notes: "When a campaign is running it's featured automatically; this applies
otherwise."

`Admin::HomePageController#update` parses `params[:featured]` (`"kind:id"`) into
`featured_kind`/`featured_id` (both nil when blank or kind not in the allowed set),
validating the kind against `%w[product set collection]`, and saves them alongside the
existing text fields.

## Out of scope

- Featuring multiple items / a rotating set.
- The campaign banner partial itself or its use on non-home pages.
- Changing campaign or pricing logic.

## Verification

No automated suite. Verify with `bin/rubocop` and an `ActionDispatch::Integration::Session`
(test env):

1. No campaign, no pick → featured card shows the first set (legacy fallback); no
   campaign banner on the home page.
2. Pick a product / set / collection in the admin → that item is featured with the
   right eyebrow, link, and image; saving persists `featured_kind`/`featured_id`.
3. Activate a campaign → the campaign is featured (overrides the pick), linking to the
   campaign page with its banner; "Featured offer" eyebrow.
4. Pick then delete the picked record → falls back cleanly (no error).
5. Selecting "None" clears the pick.
