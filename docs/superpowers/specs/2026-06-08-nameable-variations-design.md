# Nameable variations — design

## Goal

Let the studio give a variation an optional custom **name**. When a name is set, it
is used as the variation's display label everywhere it appears. When blank, the
variation falls back to today's auto-generated attribute label (e.g. "Large / Red").

## Background

A `Variant` belongs to a `Product` and is currently identified and displayed solely
by its chosen attribute values. `Variant#label` joins those values, ordered by
attribute position, into a string like "Large / Red". That label is the only
human-readable handle for a variation and is used in:

- the product-page variant picker (`app/views/products/show.html.erb:61`)
- the cart line tag (`app/views/shared/_cart_contents.html.erb:30`)
- the checkout summary (`app/views/checkout/new.html.erb:51`)
- the order-line snapshot `variant_label` (`app/controllers/checkout_controller.rb:27`)

A variation's **identity** is its set of attribute values; `VariantsController`
blocks creating two variations of the same product with an identical attribute set.

## Behavior

- A variation gains an optional free-text `name`.
- Display label = `name` if present, otherwise the attribute auto-label.
- Because every display site already calls `variant.label`, the override flows
  through with no changes at those sites.
- The attribute combination remains the variation's identity. Duplicate detection
  is unchanged: name is cosmetic only. (Two name-only variations with no attributes
  would still collide, as they do today — accepted.)

## Changes

1. **Migration** — add a nullable `name:string` column to `variants`.

2. **`Variant` model** (`app/models/variant.rb`)
   - Rename the existing attribute-join method to `options_label` (the current body
     of `label`).
   - `label` returns `name.presence || options_label`.
   - Keep `name` optional (no presence validation).

3. **Admin variant form** (`app/views/admin/variants/_form.html.erb`)
   - Add an optional "Name" text field at the top of the editor card, with a hint:
     "Leave blank to use the attribute combination."

4. **`VariantsController`** (`app/controllers/admin/variants_controller.rb`)
   - On create and update, set `name` from `params.dig(:variant, :name)`, with blank
     coerced to `nil` (e.g. `.presence`).
   - Duplicate-detection logic is untouched.

## Out of scope

- Duplicate detection / variation identity.
- The variant picker's `· <price>` suffix and storefront layout.
- Attribute management screens.

## Verification

No automated test suite exists (per `CLAUDE.md`). Verify manually:

1. Create a variation **with** a name → picker, cart, and checkout show the name.
2. Create a variation **without** a name → still shows the "Large / Red" auto-label.
3. Edit a named variation, clear the name, save → reverts to the auto-label.
