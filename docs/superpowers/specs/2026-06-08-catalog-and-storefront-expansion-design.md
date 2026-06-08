# Catalogue & Storefront Expansion — Design

**Date:** 2026-06-08
**Status:** Approved for planning

## Summary

Nine related additions to the Preciso storefront + admin, spanning content tweaks,
two new catalogue concepts (Collections, Campaigns), and one structural feature
(product Variations) that ripples into the cart and orders. Delivered as a single
spec, implemented in phases (see Implementation Order).

The guiding constraint: **simple products keep working exactly as they do today.**
Variations, campaigns, and collections are additive layers — a product with no
variations and no active campaign behaves identically to the current code.

---

## Features

### A. Quick wins (no model ripple)

1. **Logo** — replace the text brand ("Preciso / Porcelain Studio") with the cursive
   `logo.jpg` mark in the site header and footer. Copy the asset into
   `app/assets/images/preciso-logo.jpg` (Propshaft serves it; no variants needed).
   Keep an `alt="Preciso"` for accessibility.

2. **Category image** — `Category has_one_attached :image`. Upload field on the admin
   category form. Shown on the home category tiles and the shop category header; falls
   back to the existing color-wash placeholder when no image is attached.

3. **About image** — `About has_one_attached :image` (singleton). Upload field on the
   admin About form. Rendered on the storefront About page.

4. **More product images** — a product may hold many photos. No hard cap was found in
   the controller, the `multiupload` Stimulus controller, or the form (all already
   handle `multiple`), so the first implementation step is to **reproduce and locate**
   whatever is effectively limiting it (likely client- or CSS-side), then remove it.
   Acceptance: attach 5+ images to one product across saves and see them all.

5. **Contacts** — site footer (every page) gains a contact block:
   `Bianna Taynova · +359 88 544 8888 · Sofia, Vitosha blvd. 200, section A`,
   plus **Instagram** (`https://www.instagram.com/preciso_handmade/`) and
   **Facebook** (`https://www.facebook.com/PrecisoHandmade`) icon links. The About
   page also gets a compact contact block. Phone is a `tel:` link; address is plain text.

### B. Collections

A curated group of products that share a *style* (e.g. "Oro"). Distinct from a
Category (a product *type*) and a Set (items sold together for one price).

- **Model `Collection`**: `name`, `slug` (sticky, regenerated only on name change —
  mirror `Category#assign_slug`), `description`, `position`, `has_one_attached :cover`.
- **Membership is many-to-many**: a product can belong to several collections.
  Join model `CollectionMembership` (`collection_id`, `product_id`, `position`).
  `Collection has_many :products, through: :collection_memberships`.
- **Admin**: full CRUD + a product picker (multi-select of existing products).
- **Storefront**: `/collection/:slug` page listing the collection's products (reuse
  `shared/product_card`), with the cover image + description as a header. Linked from
  the main nav and footer. A collection with no products is hidden from nav.

### C. Variations

Optional per-product variants built from **globally-defined attributes**.

- **Global attributes** (new admin screen):
  - `VariantAttribute`: `name` (e.g. "Size"), `position`.
  - `VariantAttributeValue`: `variant_attribute_id`, `value` (e.g. "Large"), `position`.
  - Reusable across all products; managed once in admin.
- **Per-product variants**:
  - `Variant`: `product_id`, `price` (integer €, like product/set price), `position`,
    `has_many_attached :images`.
  - `VariantValue` (join): `variant_id`, `variant_attribute_value_id`. A variant
    selects **one or more** attribute values (the vase: a variant = {Size: Large,
    Color: Red}). `Variant has_many :variant_attribute_values, through: :variant_values`.
  - Variants are an **explicit list** — the studio adds only the combinations it makes
    (Large/Red, Small/Red, Small/Blue — never an auto-generated full matrix).
- **Simple products unchanged**: a product with zero variants uses its own `price`
  and `images`. `Product#has_variants?` gates all new behavior.
- **Admin product form** gains a **Variations** section: list existing variants
  (label + price + photos + remove), and **"Create variation"** → choose attribute
  value(s), set price, attach photos.
- **Storefront product page**: when `has_variants?`, render a **variant switcher**
  (one control group per attribute, or a list of variant labels). Selecting a variant
  swaps the displayed price, the gallery, and the add-to-cart target. Default
  selection = first variant. Gallery shows the selected variant's images, falling back
  to product-level images if the variant has none.
- **Card display**: variant products show **"from €X"** (minimum variant price);
  `Product#price_from` returns it. `primary_image` for a variant product = first
  variant's cover (fallback to product image).

### D. Campaigns

Time-boxed promotions that reduce prices on selected products and sets.

- **Model `Campaign`**: `name`, `slug`, `active` (boolean), `blurb`, optional
  `has_one_attached :banner`.
- **Model `CampaignItem`**: targets a product or set via the existing `(kind, id)`
  convention (`kind` ∈ `"product"`/`"set"`, `item_id`). Discount is **per item**, of
  one of two kinds:
  - `discount_kind = "fixed"` → `sale_price` (integer €): the item sells at this price.
  - `discount_kind = "percent"` → `percent_off` (integer 1–99): price × (1 − pct/100).
  - **Fixed** suits simple products and sets. **Percent** also applies cleanly to
    **variant** products (each variant's price is reduced by the percentage), so
    variant products may only be added with a percent discount (fixed is disabled for
    them in the picker).
- **Effective pricing** (single source of truth): a `Campaign.active` scope and a
  lookup `Campaign.discount_for(kind, id)` returning the active `CampaignItem` (or nil).
  Catalogue records expose `current_price` (and variants `current_price`) that apply
  the active discount on top of the base/variant price. The cart and checkout charge
  `current_price`; original price is shown struck-through where discounted.
- **"Promote" = activate**: when `active`, discounts go live across cards, product
  pages, cart, and checkout. Additionally, an active campaign renders an **optional
  homepage banner** (when a banner image is set) and a **campaign landing page**
  (`/campaign/:slug`) listing its discounted items.
- **Admin**: Campaigns CRUD + an item picker (choose products/sets, set discount kind
  and value per item), plus the active toggle.

---

## Data model changes

**New tables**

| Table | Key columns |
|---|---|
| `collections` | name, slug (unique), description, position, timestamps |
| `collection_memberships` | collection_id, product_id, position |
| `variant_attributes` | name, position |
| `variant_attribute_values` | variant_attribute_id, value, position |
| `variants` | product_id, price (int, default 0), position |
| `variant_values` | variant_id, variant_attribute_value_id |
| `campaigns` | name, slug (unique), active (bool, default false), blurb |
| `campaign_items` | campaign_id, kind, item_id, discount_kind, sale_price, percent_off |

**Active Storage attachments** (no new columns): `Category#image`, `About#image`,
`Collection#cover`, `Campaign#banner`, `Variant#images` (many).

**Altered tables**

- `order_lines`: add `variant_id` (int, nullable) and `variant_label` (string,
  nullable) so a placed order snapshots which variation was bought.

**Session cart shape** (not a DB change): lines become
`{"kind", "id", "variant_id", "qty"}`. `variant_id` is nil for sets and simple
products. `Cart#add/remove/set_qty/find` match on `variant_id` too, so Large/Red and
Small/Blue are distinct lines. `Cart::Line` carries the resolved variant and uses
`current_price` for `subtotal`.

---

## Cart & checkout ripple (the one risky area)

This is the only place existing behavior changes shape, so it gets explicit care:

1. **`Cart`** — line hashes gain `variant_id`; `find` matches `(kind, id, variant_id)`;
   `add` accepts an optional variant; `detailed` resolves the `Variant` and uses
   `current_price` for pricing and the variant's cover for the thumbnail.
2. **Add-to-cart UI** — the product page's button passes `variant_id` for variant
   products. The cart Turbo Stream views render the variant label under the item name.
3. **Checkout** — `OrderLine` snapshots `variant_id`, `variant_label`, and the charged
   `current_price`. Existing simple/set flows are unaffected (variant_id nil).
4. **Back-compat** — any cart line already in a session without `variant_id` is treated
   as nil (simple product), so existing sessions don't break.

---

## Admin surfaces (new / changed)

- **New nav items** (in `admin/shared/_sidebar`): Attributes, Collections, Campaigns.
- **New controllers**: `Admin::VariantAttributesController` (+ values),
  `Admin::CollectionsController`, `Admin::CampaignsController`,
  `Admin::VariantsController` (nested under product, or handled inline on the product
  form — decided at plan time).
- **Changed**: product form (Variations section, lifted image cap), category form
  (image), About form (image).
- **Routes**: `namespace :admin` gains `resources :collections`, `:campaigns`,
  `:variant_attributes` (values nested), and variants under products.
  Storefront gains `get "collection/:slug"` and `get "campaign/:slug"`.

Admin views remain untracked by analytics (per the existing `track` rule).

---

## Storefront surfaces (new / changed)

- **Header/footer**: logo image; footer contact + social block.
- **Home**: category tiles use category images; optional active-campaign banner;
  (optional) a collections strip.
- **Shop category page**: header uses the category image.
- **Product page**: variant switcher; struck-through campaign pricing.
- **Product/record cards**: "from €X" for variant products; campaign sale price.
- **About page**: about image + contact block.
- **New pages**: `/collection/:slug`, `/campaign/:slug`.

---

## Out of scope (YAGNI)

- Per-variant inventory/stock counts and SKUs (price + photos only).
- Auto-generated full variant matrices (variants are an explicit list).
- Stacking multiple campaigns on one item (first active discount wins; document it).
- Scheduled start/end dates for campaigns (manual `active` toggle in v1).
- Collections of sets (collections group products only).
- A contact form (contacts are displayed details + `tel:`/social links).

---

## Implementation order (phases)

1. **Quick wins** — logo, category image, About image, contacts/social, lift product
   image cap. Independent, shippable immediately.
2. **Collections** — model, admin CRUD + picker, storefront page, nav/footer links.
3. **Campaigns** — models, effective-pricing layer, admin, storefront banner/page,
   struck-through prices in cards/cart/checkout.
4. **Variations** — attributes admin, variants on the product form, storefront
   switcher, and the cart/order changes. Done last because it carries the most risk
   and touches the cart; campaigns' `current_price` layer from phase 3 is reused.

Each phase is verifiable on its own (no automated tests exist; verify by exercising
the admin + storefront flows and running `bin/rubocop` + `bin/brakeman`).
