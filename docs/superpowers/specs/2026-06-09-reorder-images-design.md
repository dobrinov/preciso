# Reorder product & variant images

## Goal

Let the admin rearrange the images of multi-image records (products and variants)
by drag-and-drop, which also sets the cover (first image). Single-image records
(category, collection, campaign, set, about) are unaffected.

## Background

`Product` and `Variant` both `has_many_attached :images`; `primary_image` is
`images.first` and the gallery is `images`, both in Active Storage's default order
(attachment id ascending). There is no explicit ordering today.

**Verified constraint:** reassigning `record.images = [reordered blobs]` does NOT
reorder — Active Storage keeps the existing attachments (still ordered by id) when
the same blobs are assigned. So ordering must be explicit, sorted at read time. No
blob is reattached/purged for reordering (safe).

The admin image grid is driven by the `multiupload` Stimulus controller (add files,
mark existing for removal). Controllers `Admin::ProductsController` and
`Admin::VariantsController` have `attach_images` (new files) + `purge_images`
(`remove_image_ids`).

## Data model

Add `image_order` (text, nullable) to `products` and `variants` — a JSON array of
Active Storage attachment ids in display order.

A concern `app/models/concerns/image_ordering.rb`:

```ruby
module ImageOrdering
  extend ActiveSupport::Concern
  included { serialize :image_order, type: Array, coder: JSON }

  # Attachments sorted by the stored order; anything not listed (new uploads)
  # sorts last, by id, so the result is always stable.
  def ordered_images
    return [] unless images.attached?
    ord = Array(image_order)
    images.attachments.sort_by { |a| [ ord.index(a.id) || Float::INFINITY, a.id ] }
  end
end
```

`Product` and `Variant` `include ImageOrdering`. `primary_image`:
- `Variant#primary_image` → `ordered_images.first` (when attached).
- `Product#primary_image` → `ordered_images.first` when images attached, else the
  existing variant-cover fallback (`variants.detect(&:primary_image)&.primary_image`).

## Read path (use ordered_images where order matters)

- `app/views/products/show.html.erb`: the `gallery_imgs` source (`@product.images`,
  the variant's `images`) and the variant-chip `v.images.map { url_for }` → the
  `ordered_images` equivalents.
- Admin product & variant forms: render existing tiles in `ordered_images` order.
- `primary_image` already covers `cover_attachment` / product cards / media_for.

## Admin UI — drag-and-drop

Extend the `multiupload` Stimulus controller into a sortable grid (native HTML5
drag-and-drop, no library):
- Existing-image tiles get `draggable="true"` and `data-image-id="<attachment id>"`.
- New-upload preview tiles are also `draggable` and carry a `data-new` marker.
- `dragstart`/`dragover`/`drop`/`dragend` handlers reorder the tile DOM within the
  grid (move the dragged tile before/after the drop target).
- After any reorder (and after add/remove), the controller rewrites a hidden field
  `image_order_tokens` to the current tile order: each existing tile → its
  `data-image-id`; each new tile → the literal `new`. Removed (marked) tiles are
  excluded from the tokens.
- The first tile is labelled "Cover".

The new-file `<input type=file multiple>` continues to submit the buffered files (in
upload order), as today.

## Controller (Admin product & variant create/update)

Order of operations, in a shared private method (e.g. `apply_images(record)` per
controller, mirroring today's attach/purge):

1. `purge_images` — purge attachments whose id is in `remove_image_ids` (unchanged).
2. `attach_images` — attach the newly uploaded files (unchanged). Capture the ids of
   just-attached attachments (current attachment ids minus the pre-attach set), in
   attach order.
3. Resolve `params[:image_order_tokens]` (array, in tile order) into an id list:
   - an existing-id token → that id, if it is still an attached image id;
   - a `new` token → the next id from the just-attached list.
   Append any still-attached ids not produced by the tokens (safety net) at the end.
   Save the result to `record.image_order`.

For `create`, the same applies after the record + initial attachments are saved.

## Files

- Migration: `products` + `variants` `image_order:text`.
- New: `app/models/concerns/image_ordering.rb`.
- Modify: `app/models/product.rb`, `app/models/variant.rb` (include + primary_image),
  `app/controllers/admin/products_controller.rb`,
  `app/controllers/admin/variants_controller.rb`,
  `app/javascript/controllers/multiupload_controller.js`,
  `app/views/admin/products/_form.html.erb`,
  `app/views/admin/variants/_form.html.erb`,
  `app/views/products/show.html.erb`.

## Out of scope

- Reordering single-image records.
- A separate "cover" flag (cover = first image).
- Reordering images of sets/collections/categories/campaigns.
- Touch drag (native DnD; desktop-first, per the chosen approach).

## Verification

No automated suite. `bin/rubocop` + a test-env `ActionDispatch::Integration::Session`:

1. Attach 3 images to a product, submit an `image_order_tokens` reversing them →
   `product.ordered_images` and `primary_image` reflect the new order; all 3 blobs
   still download (none purged).
2. Add a new upload with a `new` token placed first → it becomes the cover; existing
   images keep their relative order.
3. Mark one for removal → it's purged and dropped from `image_order`; the rest stay
   ordered.
4. The product page gallery and variant chips render images in `ordered_images` order.
5. A record with no `image_order` yet (legacy) renders images in id order (unchanged).
