# Variant selection via per-attribute dropdowns — design

## Goal

Replace the storefront's radio-chip variant picker (one chip per whole
combination, e.g. "small / blue · €28") with **one dropdown per attribute**
(Size, Colour, …). The chosen combination is resolved to a variant on the
client. When no variant matches the selected combination, show an "unavailable"
message, hide the price, and disable ordering.

## Background

A `Product` `has_many :variants`. Each `Variant` has `variant_values` joining it
to one `VariantAttributeValue` per attribute; `Variant#label` joins those values
("small / blue", ordered by attribute position). `Variant#variant_attribute_value_ids`
returns the value ids. Pricing flows through `Variant#current_price_via_product`
(applies any active campaign discount) vs. `Variant#price` (base).

Today (`app/views/products/show.html.erb:47-65`) the picker renders one radio per
variant, each carrying `data-variant-id`, `data-price-plain`, `data-price-label`,
and `data-images`. `variants_controller.js` swaps the price, gallery, and the
hidden `variant_id` when a radio is selected. The add-to-cart form posts
`variant_id`; cart/checkout resolve the variant and snapshot its label.

`products_controller#show` already loads
`@variants = @product.variants.includes(:variant_attribute_values, images_attachments: :blob)`.

## UI

For each attribute used by this product's variants (ordered by
`VariantAttribute#position`), render a labelled `<select>`. Each select's options
are the distinct `VariantAttributeValue`s of that attribute **that appear in this
product's variants** (ordered by `VariantAttributeValue#position`); option value =
the value id, option text = `value`. The first variant's combination is
pre-selected, so the page loads on a valid, priced, orderable state.

The radio-chip markup (`show.html.erb:47-65`) is removed.

## Data flow

### Variant lookup map (server → client)

A variant's identity is the **set of its attribute-value ids**. The view builds a
JSON map keyed by each variant's sorted value-ids joined with `-`:

```ruby
variant_map = @variants.each_with_object({}) do |v, h|
  cur  = v.current_price_via_product
  base = v.price
  urls = v.images.attached? ? v.images.map { |i| url_for(i) }
                            : (@product.images.attached? ? @product.images.map { |i| url_for(i) } : [])
  h[v.variant_attribute_value_ids.sort.join("-")] = {
    variantId:  v.id,
    pricePlain: money(cur),
    priceLabel: (cur < base ? "<span class='price-now'>#{money cur}</span> <span class='price-was'>#{money base}</span>" : money(cur)),
    images:     urls
  }
end
```

Rendered as `data-variants-map="<%= variant_map.to_json %>"` on the
`data-controller="variants"` root. `to_json` escapes `<`/`>` as `<`/`>`
(NOT the `\/` that `escape_javascript` produces), so the `priceLabel` HTML
round-trips cleanly through `JSON.parse` and into `innerHTML`. (This is the same
class of bug fixed in commit 7a0e857 — do not use `escape_javascript` here.)

### Selection → resolution (client)

On any dropdown `change` (and on `connect`), the controller collects the selected
option value from each `attrSelect`, sorts and joins them into the same `-` key,
and looks it up in the map.

- **Found:** `priceTarget.innerHTML = priceLabel`; `variantIdTarget.value = variantId`;
  `addLabelTarget.textContent = "Add — " + pricePlain`; enable the add button;
  show the price element; hide the unavailable message; swap gallery images
  (existing logic) when the variant has images.
- **Not found:** hide the price element; show the unavailable message
  ("This combination isn't available."); clear `variantIdTarget.value`; disable
  the add button.

## Components touched

1. **`app/views/products/show.html.erb`**
   - Build the ordered attribute→values structure for the product and the
     `variant_map`.
   - Replace the chip picker with one `<select data-variants-target="attrSelect"
     data-action="change->variants#select">` per attribute, first variant's values
     pre-selected.
   - Initial price: `price_tag(@product, variant: @variants.first)` (reuses the
     safe-span helper) instead of "from €X".
   - Add the map to the `data-controller="variants"` element.
   - Add an unavailable-message element: `data-variants-target="unavailable"`,
     hidden by default.
   - Add `data-variants-target="addButton"` to the Add submit button.

2. **`app/javascript/controllers/variants_controller.js`**
   - New targets: `attrSelect`, `unavailable`, `addButton` (keep `price`,
     `variantId`, `addLabel`, `mainImage`, `thumbs`; drop `radio`).
   - Parse the map from `this.element.dataset.variantsMap` in `connect()`.
   - Replace `select(e)`/radio logic with a `select()` that reads the dropdowns,
     and an `apply()` implementing the found/not-found behavior above.

3. **`app/assets/stylesheets/application.css`**
   - Minimal styling for the dropdown row (`.variant-field` / select) and the
     unavailable message, consistent with the existing hand-written design system.

## Out of scope

- Admin variant creation/editing (unchanged).
- Cart and checkout (unchanged — still resolve via `variant_id` and snapshot the
  label).
- "Smart" dropdowns that grey out impossible options — explicitly not wanted; the
  unavailable message is the intended feedback for missing combinations.
- Changing pricing or campaign logic.

## Edge cases

- **One attribute:** a single dropdown; each option maps to a variant.
- **Variant missing an attribute:** its key has fewer ids than a full selection,
  so it never matches and reads as "unavailable". Acceptable for consistently
  built products.
- **Variant without own images:** falls back to the product's images (current
  behavior preserved).
- **Default load:** first variant pre-selected → valid, priced, orderable.

## Verification

No automated test suite (per `CLAUDE.md`). Verify manually with a multi-attribute,
sparse-variant product (a variant combination deliberately missing):

1. One dropdown renders per attribute, options limited to the product's values.
2. Page loads with the first variant selected, showing its price and an enabled Add.
3. Selecting an existing combination updates price, "Add — €X", gallery, and the
   hidden `variant_id`; add-to-cart adds that variant.
4. Selecting a non-existent combination shows the unavailable message, hides the
   price, and disables the Add button.
5. A discounted variant shows the struck-through original price (no escaped HTML).
