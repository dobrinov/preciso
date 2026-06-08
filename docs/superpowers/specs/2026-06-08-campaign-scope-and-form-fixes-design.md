# Campaign scope + form fixes — design

## Goals

Three related improvements to admin campaigns:

1. **Campaign scope** — let a campaign apply to *all products* with one percentage,
   instead of only a hand-picked selection.
2. **Single active campaign** — enforce that at most one campaign is active.
3. **Form clarity** — fix two confusing behaviors in the campaign form:
   both the € and % inputs showing at once, and an enabled item silently failing
   to save when its value is left blank.

## Background

A `Campaign` has many `CampaignItem`s (`dependent: :destroy`). Each item points at a
`Product` or `ProductSet` (`kind` + `item_id`) and carries a `discount_kind`
(`"fixed"` | `"percent"`) with either `sale_price` (fixed target €) or `percent_off`
(1..99). `CampaignItem#price_for(base)` returns the discounted integer price.

Discounts resolve at render time through `Campaign.discount_for(kind, id)`, which today
returns the first active campaign's matching `CampaignItem` (or nil). `Product#current_price`
and `ProductSet#current_price` call it and then `price_for(base)` — both via a per-instance
memoized `campaign_item` helper. Callers use **only** `price_for`; no other `CampaignItem`
method is needed on the price path.

The admin form (`app/views/admin/campaigns/_form.html.erb`) renders a table with a row per
product/set: a checkbox, a discount-kind `<select>`, and **both** a `sale_price` and a
`percent_off` number field. The controller's `rebuild_items` destroys all items and
recreates the enabled ones, **silently skipping** any enabled row whose required value is
blank (`next if value.blank?`).

The storefront campaign page (`campaigns#show`) builds `@records` from
`@campaign.campaign_items.filter_map(&:record)`.

## Data model

Add two columns to `campaigns`:

- `all_products` — boolean, `null: false`, `default: false`.
- `percent_off` — integer, nullable (used only when `all_products` is true).

No new tables. The selection path keeps using `campaign_items` unchanged.

## Behavior

### Scope toggle

- **All products** (`all_products: true`): the campaign discounts every `Product` and
  `ProductSet` by `percent_off`. Percentage only — fixed-€ is not offered for this scope
  (a single fixed target price across heterogeneous and variation-priced items is
  incoherent). Applies to items added after the campaign is created, and to products
  with variations (each variant's price is reduced by the percentage).
- **Selection of products** (`all_products: false`): the existing per-item table.
  Unchanged: per-row fixed €/% choice; products with variations remain percent-only.

### Discount resolution

`Campaign.discount_for(kind, id)` becomes:

```ruby
def self.discount_for(kind, id)
  campaign = active.first
  return nil unless campaign
  if campaign.all_products?
    CampaignItem.new(discount_kind: "percent", percent_off: campaign.percent_off)
  else
    campaign.campaign_items.find_by(kind: kind.to_s, item_id: id)
  end
end
```

The all-products branch returns a **transient** (unsaved) `CampaignItem` whose
`price_for(base)` computes the percentage. `Product`/`ProductSet#current_price` need no
change. `active.first` is deterministic via the model's `default_scope { order(:id) }`.

### Single active campaign

A validation on `Campaign`, run only when `active` is true:

```ruby
validate :single_active_campaign, if: :active

def single_active_campaign
  return unless Campaign.where(active: true).where.not(id: id).exists?
  errors.add(:base, "Another campaign is already active — deactivate it before activating this one.")
end
```

This blocks (does not silently switch off) a second active campaign. Existing seed data
with multiple active rows still resolves deterministically (lowest id) until re-saved.

### Percent validation for all-products scope

```ruby
validates :percent_off, presence: true, numericality: { only_integer: true, in: 1..99 },
          if: :all_products?
```

`percent_off` is ignored (not validated) when `all_products` is false.

### Storefront campaign page

`campaigns#show` resolves `@records` by scope:

```ruby
@records = if @campaign.all_products?
  Product.order(:id).to_a + ProductSet.order(:id).to_a
else
  @campaign.campaign_items.filter_map(&:record)
end
```

Product cards already render discounted prices through `current_price`.

## Form changes

### Scope toggle + conditional sections

Two radio buttons bound to `:all_products` ("All products" / "Selection of products").
A Stimulus controller (`campaign-scope`) shows the percentage field when "All products"
is selected and the items table when "Selection of products" is selected, switching live.

### One input per row (selection table)

The same or a sibling Stimulus controller shows, per row, **only** the input matching the
row's selected `discount_kind` — the € field for "fixed", the % field for "percent" —
and updates live when the dropdown changes. Initial visibility matches the row's current
value (or the default kind for a new row). Follow the existing Stimulus patterns in
`app/javascript/controllers/` (e.g. `variants_controller.js`, `tone_controller.js`).

### Controller: validate items before saving

`campaign_params` permits `:all_products` and `:percent_off` in addition to the current
`:name, :blurb, :active`.

Create/update validate the whole form **before** persisting:

1. Run `@campaign.valid?` (populates name/slug/percent/single-active errors).
2. If scope is "selection", append an error for each enabled item row with a blank value:
   `"#{record name}: enter a #{dk == 'fixed' ? 'price' : 'percentage'}"`.
3. If there are no errors, `save!` then `rebuild_items` + `attach_banner`; otherwise
   re-render `:new` / `:edit` with status `:unprocessable_entity` and nothing persisted.

`rebuild_items` clears items, then returns early when `all_products?` (so switching
all→selection clears stale rows and all-products campaigns hold no items). The per-row
blank guard can stay as defense-in-depth, but blank values now surface as errors rather
than being silently dropped.

## Out of scope

- Multiple simultaneous active campaigns.
- Scheduling / date ranges.
- Per-category or other scopes beyond all/selection.
- Changing the fixed-discount math (`min(sale_price, base)`).

## Verification

No automated test suite exists (per `CLAUDE.md`). Verify with `bin/rubocop` plus manual
checks in the running app:

1. **All-products %**: create an all-products campaign at 20%, activate it, confirm every
   product and set (including a variation product) shows a 20%-reduced price on the shop
   and on the campaign page.
2. **Selection still works**: a selection campaign discounts only its ticked items.
3. **Single active**: activating a second campaign while one is active fails with the
   error and persists nothing.
4. **One input per row**: in the selection table, choosing "Fixed €" shows only the €
   field; "% off" shows only the % field; switching toggles live.
5. **Blank value error**: ticking an item and leaving its value blank shows a per-item
   error and re-renders without saving.
