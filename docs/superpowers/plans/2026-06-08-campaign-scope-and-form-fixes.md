# Campaign Scope + Form Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a campaign discount all products by one percentage (vs. the existing per-item selection), enforce a single active campaign, and fix two confusing campaign-form behaviors (both €/% inputs always visible; enabled items silently dropped when their value is blank).

**Architecture:** Add `all_products` (boolean) + `percent_off` (integer) to `campaigns`. `Campaign.discount_for` returns a transient percent `CampaignItem` when the active campaign is all-products, so `current_price` is unchanged. A new `campaign-form` Stimulus controller toggles scope sections and per-row inputs. The admin controller validates the campaign and item rows *before* persisting, surfacing per-item errors instead of skipping.

**Tech Stack:** Rails 8.1, SQLite, ERB, Hotwire/Stimulus over importmap (controllers auto-register via `eagerLoadControllersFrom`). No automated test suite (per `CLAUDE.md`) — verification is `bin/rubocop`, `bin/rails runner` console checks, and manual checks in the running app.

---

### Task 1: Add `all_products` and `percent_off` columns to campaigns

**Files:**
- Create: `db/migrate/<timestamp>_add_scope_to_campaigns.rb` (generated)
- Modify: `db/schema.rb` (auto-updated)

- [ ] **Step 1: Generate the migration**

Run:
```bash
bin/rails generate migration AddScopeToCampaigns all_products:boolean percent_off:integer
```

- [ ] **Step 2: Set the boolean default and null constraint**

Open the generated migration and make its body exactly:
```ruby
class AddScopeToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :all_products, :boolean, null: false, default: false
    add_column :campaigns, :percent_off, :integer
  end
end
```
(`all_products` must be non-null with a `false` default; `percent_off` stays nullable.)

- [ ] **Step 3: Run the migration**

Run:
```bash
bin/rails db:migrate
```
Expected: `db/schema.rb` `create_table "campaigns"` now contains `t.boolean "all_products", default: false, null: false` and `t.integer "percent_off"`.

- [ ] **Step 4: Commit**

```bash
git add db/migrate db/schema.rb
git commit -m "Add all_products and percent_off columns to campaigns"
```

---

### Task 2: Campaign model — scope-aware discount + validations

**Files:**
- Modify: `app/models/campaign.rb`

- [ ] **Step 1: Rewrite `discount_for` to be scope-aware**

In `app/models/campaign.rb`, replace the current `self.discount_for` method:
```ruby
  # The active discount for a catalogue item, or nil. First active campaign wins.
  def self.discount_for(kind, id)
    CampaignItem.joins(:campaign)
                .where(campaigns: { active: true }, kind: kind.to_s, item_id: id)
                .order("campaigns.id")
                .first
  end
```
with:
```ruby
  # The active discount for a catalogue item, or nil. At most one campaign is
  # active (enforced by validation); an all-products campaign discounts every
  # item by percent_off via a transient (unsaved) CampaignItem.
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

- [ ] **Step 2: Add the percent and single-active validations**

In `app/models/campaign.rb`, just after the existing `validates :slug, ...` line, add:
```ruby
  validates :percent_off, presence: true, numericality: { only_integer: true, in: 1..99 },
            if: :all_products?
  validate :single_active_campaign, if: :active
```
Then add this private method (in the `private` section, e.g. above `assign_slug`):
```ruby
  def single_active_campaign
    return unless Campaign.where(active: true).where.not(id: id).exists?
    errors.add(:base, "Another campaign is already active — deactivate it before activating this one.")
  end
```

- [ ] **Step 3: Verify in the console**

Run:
```bash
bin/rails runner '
  # all-products discount resolves to a transient percent CampaignItem
  c = Campaign.new(name: "Test", all_products: true, percent_off: 20, active: false)
  puts "all_products valid? #{c.valid?} errors=#{c.errors.full_messages}"
  d = CampaignItem.new(discount_kind: "percent", percent_off: 20)
  puts "price_for(100)=#{d.price_for(100)} (expect 80)"
  # percent required when all_products
  bad = Campaign.new(name: "NoPct", all_products: true)
  bad.valid?; puts "missing percent errors include percent? #{bad.errors.attribute_names.include?(:percent_off)}"
'
```
Expected: the all-products campaign is valid; `price_for(100)=80`; the missing-percent campaign reports a `percent_off` error.

- [ ] **Step 4: Lint**

Run:
```bash
bin/rubocop app/models/campaign.rb
```
Expected: no offenses.

- [ ] **Step 5: Commit**

```bash
git add app/models/campaign.rb
git commit -m "Campaign: scope-aware discount_for + percent and single-active validations"
```

---

### Task 3: Storefront campaign page — records by scope

**Files:**
- Modify: `app/controllers/campaigns_controller.rb`

- [ ] **Step 1: Resolve `@records` by scope**

In `app/controllers/campaigns_controller.rb`, replace this line in `show`:
```ruby
    @records = @campaign.campaign_items.filter_map(&:record)
```
with:
```ruby
    @records = if @campaign.all_products?
      Product.order(:id).to_a + ProductSet.order(:id).to_a
    else
      @campaign.campaign_items.filter_map(&:record)
    end
```

- [ ] **Step 2: Verify in the console**

Run:
```bash
bin/rails runner '
  puts "products=#{Product.count} sets=#{ProductSet.count} total_for_all=#{Product.count + ProductSet.count}"
'
```
Expected: prints counts; `total_for_all` equals products + sets (what an all-products campaign page will list).

- [ ] **Step 3: Lint**

Run:
```bash
bin/rubocop app/controllers/campaigns_controller.rb
```
Expected: no offenses.

- [ ] **Step 4: Commit**

```bash
git add app/controllers/campaigns_controller.rb
git commit -m "Campaign page lists all products when scope is all-products"
```

---

### Task 4: Admin controller — permit scope params, validate items before saving

**Files:**
- Modify: `app/controllers/admin/campaigns_controller.rb`

- [ ] **Step 1: Permit the new params**

In `app/controllers/admin/campaigns_controller.rb`, change `campaign_params`:
```ruby
    def campaign_params
      params.require(:campaign).permit(:name, :blurb, :active)
    end
```
to:
```ruby
    def campaign_params
      params.require(:campaign).permit(:name, :blurb, :active, :all_products, :percent_off)
    end
```

- [ ] **Step 2: Rewrite `create` to validate before persisting**

Replace the `create` action:
```ruby
    def create
      @campaign = Campaign.new(campaign_params)
      if @campaign.save
        rebuild_items(@campaign)
        attach_banner(@campaign)
        redirect_to admin_campaigns_path
      else
        render :new, status: :unprocessable_entity
      end
    end
```
with:
```ruby
    def create
      @campaign = Campaign.new(campaign_params)
      if valid_with_items?(@campaign)
        @campaign.save!
        rebuild_items(@campaign)
        attach_banner(@campaign)
        redirect_to admin_campaigns_path
      else
        render :new, status: :unprocessable_entity
      end
    end
```

- [ ] **Step 3: Rewrite `update` to validate before persisting**

Replace the `update` action:
```ruby
    def update
      if @campaign.update(campaign_params)
        rebuild_items(@campaign)
        attach_banner(@campaign)
        @campaign.banner.purge if params.dig(:campaign, :remove_banner) == "1"
        redirect_to admin_campaigns_path
      else
        render :edit, status: :unprocessable_entity
      end
    end
```
with:
```ruby
    def update
      @campaign.assign_attributes(campaign_params)
      if valid_with_items?(@campaign)
        @campaign.save!
        rebuild_items(@campaign)
        attach_banner(@campaign)
        @campaign.banner.purge if params.dig(:campaign, :remove_banner) == "1"
        redirect_to admin_campaigns_path
      else
        render :edit, status: :unprocessable_entity
      end
    end
```

- [ ] **Step 4: Add the validation helpers**

In the `private` section, add these two methods (e.g. just above `rebuild_items`):
```ruby
    # True only when the campaign AND its item rows are all valid. Runs the
    # model validations, then (for selection scope) flags any enabled row left
    # without its required value, so nothing is silently dropped.
    def valid_with_items?(campaign)
      campaign.valid?
      add_item_errors(campaign) unless campaign.all_products?
      campaign.errors.empty?
    end

    def add_item_errors(campaign)
      params.fetch(:items, {}).each do |key, attrs|
        next if attrs[:enabled] != "1"
        dk = attrs[:discount_kind].presence || "fixed"
        value = dk == "fixed" ? attrs[:sale_price] : attrs[:percent_off]
        next if value.present?
        kind, id = key.split("-", 2)
        rec = (kind == "set" ? ProductSet : Product).find_by(id: id)
        label = rec&.name || key
        campaign.errors.add(:base, "#{label}: enter a #{dk == 'fixed' ? 'price' : 'percentage'}")
      end
    end
```

- [ ] **Step 5: Make `rebuild_items` skip items for all-products scope**

In `rebuild_items`, change the opening:
```ruby
    def rebuild_items(campaign)
      campaign.campaign_items.destroy_all
      # params[:items] is ActionController::Parameters (or nil when none ticked);
```
to:
```ruby
    def rebuild_items(campaign)
      campaign.campaign_items.destroy_all
      return if campaign.all_products?
      # params[:items] is ActionController::Parameters (or nil when none ticked);
```
(Leave the rest of the method unchanged — the per-row `next if value.blank?` guard stays as defense-in-depth, but blank values are now caught earlier as errors.)

- [ ] **Step 6: Lint**

Run:
```bash
bin/rubocop app/controllers/admin/campaigns_controller.rb
```
Expected: no offenses.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/admin/campaigns_controller.rb
git commit -m "Admin campaigns: scope params + validate items before saving"
```

---

### Task 5: Stimulus controller for the campaign form

**Files:**
- Create: `app/javascript/controllers/campaign_form_controller.js`

- [ ] **Step 1: Create the controller**

Create `app/javascript/controllers/campaign_form_controller.js` with exactly:
```javascript
import { Controller } from "@hotwired/stimulus"

// Campaign form: switch between all-products and selection scope, and within the
// selection table show only the input (€ or %) that matches each row's discount type.
export default class extends Controller {
  static targets = ["all", "selection"]

  connect() {
    this.syncScope()
    this.element
      .querySelectorAll("[data-kind-select]")
      .forEach((select) => this.syncRow(select))
  }

  scopeChanged() {
    this.syncScope()
  }

  kindChanged(event) {
    this.syncRow(event.target)
  }

  syncScope() {
    const checked = this.element.querySelector(
      "input[name='campaign[all_products]']:checked"
    )
    const all = checked?.value === "true"
    if (this.hasAllTarget) this.allTarget.hidden = !all
    if (this.hasSelectionTarget) this.selectionTarget.hidden = all
  }

  syncRow(select) {
    const row = select.closest("tr")
    if (!row) return
    const percent = select.value === "percent"
    const fixed = row.querySelector(".js-fixed")
    const pct = row.querySelector(".js-percent")
    if (fixed) fixed.hidden = percent
    if (pct) pct.hidden = !percent
  }
}
```

- [ ] **Step 2: Confirm importmap auto-loads it**

No registration needed — `app/javascript/controllers/index.js` calls `eagerLoadControllersFrom("controllers", application)`, which loads any `*_controller.js`. The file name `campaign_form_controller.js` maps to the identifier `campaign-form`. Verify the file exists and is syntactically valid:
```bash
node --check app/javascript/controllers/campaign_form_controller.js && echo "syntax OK"
```
Expected: `syntax OK`.

- [ ] **Step 3: Commit**

```bash
git add app/javascript/controllers/campaign_form_controller.js
git commit -m "Add campaign-form Stimulus controller for scope + per-row input toggles"
```

---

### Task 6: Wire the campaign form to the scope toggle and per-row inputs

**Files:**
- Modify: `app/views/admin/campaigns/_form.html.erb`

- [ ] **Step 1: Attach the controller to the form**

Change the `form_with` opening (line 17):
```erb
<%= form_with model: [:admin, @campaign], html: { multipart: true } do |f| %>
```
to:
```erb
<%= form_with model: [:admin, @campaign], html: { multipart: true, data: { controller: "campaign-form" } } do |f| %>
```

- [ ] **Step 2: Add the scope radios and all-products percentage field**

Immediately after the "Active" checkbox `<label>` block (the one ending at line 30, before `<div class="field">` for "Discounted items"), insert:
```erb
      <div class="field">
        <div class="field-label">Scope</div>
        <div class="value-chips">
          <label class="chip">
            <%= f.radio_button :all_products, false, checked: !@campaign.all_products?, data: { action: "change->campaign-form#scopeChanged" } %>
            <span>Selection of products</span>
          </label>
          <label class="chip">
            <%= f.radio_button :all_products, true, checked: @campaign.all_products?, data: { action: "change->campaign-form#scopeChanged" } %>
            <span>All products</span>
          </label>
        </div>
      </div>

      <div class="field" data-campaign-form-target="all">
        <div class="field-label">Percentage off all products</div>
        <%= f.number_field :percent_off, value: @campaign.percent_off, min: 1, max: 99, placeholder: "%", class: "input sm", style: "width:90px" %>
        <div class="field-hint">Applies to every product and set, including future ones. Percentage only.</div>
      </div>
```

- [ ] **Step 3: Wrap the items table in the selection target**

Wrap the existing "Discounted items" `<div class="field">` block (currently lines 32–54, from `<div class="field">` containing the field-label "Discounted items" through its closing `</div>` after the `</table>`) in a target wrapper. Change the opening of that block:
```erb
      <div class="field">
        <div class="field-label">Discounted items</div>
```
to:
```erb
      <div data-campaign-form-target="selection">
      <div class="field">
        <div class="field-label">Discounted items</div>
```
and add a matching `</div>` immediately after that block's existing closing `</div>` (the one right after `</table>`), so the new wrapper encloses the whole items field.

- [ ] **Step 4: Merge the €/% cells into one toggling value column**

Replace the discount-kind select cell and the two value cells (currently lines 43–50):
```erb
              <td>
                <% percent_only = kind == "product" && rec.respond_to?(:has_variants?) && rec.has_variants? %>
                <%= select_tag "items[#{key}][discount_kind]",
                      options_for_select(percent_only ? [["% off", "percent"]] : [["Fixed €", "fixed"], ["% off", "percent"]], ci&.discount_kind),
                      class: "input sm" %>
              </td>
              <td><%= number_field_tag "items[#{key}][sale_price]", ci&.sale_price, min: 0, placeholder: "€", class: "input sm", style: "width:90px" %></td>
              <td><%= number_field_tag "items[#{key}][percent_off]", ci&.percent_off, min: 1, max: 99, placeholder: "%", class: "input sm", style: "width:70px" %></td>
```
with:
```erb
              <td>
                <% percent_only = kind == "product" && rec.respond_to?(:has_variants?) && rec.has_variants? %>
                <%= select_tag "items[#{key}][discount_kind]",
                      options_for_select(percent_only ? [["% off", "percent"]] : [["Fixed €", "fixed"], ["% off", "percent"]], ci&.discount_kind),
                      class: "input sm", data: { kind_select: "", action: "change->campaign-form#kindChanged" } %>
              </td>
              <td>
                <%= number_field_tag "items[#{key}][sale_price]", ci&.sale_price, min: 0, placeholder: "€", class: "input sm js-fixed", style: "width:90px" %>
                <%= number_field_tag "items[#{key}][percent_off]", ci&.percent_off, min: 1, max: 99, placeholder: "%", class: "input sm js-percent", style: "width:70px" %>
              </td>
```

- [ ] **Step 4b: Verify the ERB renders (authenticated request)**

Start the server, then fetch the new-campaign form with an admin session and confirm the scope controls and toggling markup are present:
```bash
bin/rails server -d
J=$(mktemp)
TOKEN=$(curl -s -c "$J" http://localhost:3000/admin/login | grep -o 'name="authenticity_token" value="[^"]*"' | head -1 | sed 's/.*value="//;s/"//')
curl -s -b "$J" -c "$J" -o /dev/null -d "authenticity_token=$TOKEN&password=studio" http://localhost:3000/admin/login
curl -s -b "$J" http://localhost:3000/admin/campaigns/new | grep -oE 'data-controller="campaign-form"|campaign\[all_products\]|data-campaign-form-target="all"|data-campaign-form-target="selection"|js-fixed|js-percent|campaign-form#kindChanged' | sort -u
```
Expected output includes each of: `data-controller="campaign-form"`, `campaign[all_products]`, `data-campaign-form-target="all"`, `data-campaign-form-target="selection"`, `js-fixed`, `js-percent`, `campaign-form#kindChanged`.
Then stop only this server: `kill $(lsof -ti :3000)` (leave any servers on other ports alone).

- [ ] **Step 5: Commit**

```bash
git add app/views/admin/campaigns/_form.html.erb
git commit -m "Campaign form: scope toggle, all-products percentage, one input per row"
```

---

### Task 7: End-to-end manual verification

**Files:** none (verification only)

- [ ] **Step 1: Reset to a clean demo state and start the server**

Run:
```bash
bin/rails db:reset
bin/rails server -d
```
Log into `/admin` (password: `studio`).

- [ ] **Step 2: All-products percentage applies storewide**

1. Admin → Campaigns → New. Set Name, pick **All products**, enter `20`, tick **Active**, Create.
2. The percentage field is visible and the items table is hidden while "All products" is selected.
3. Visit the storefront shop and a product page (including a product **with variations**): prices show a 20% reduction.
4. Visit `/campaign/<slug>`: every product and set is listed, each at the reduced price.

Expected: the 20% discount applies everywhere, including variation products.

- [ ] **Step 3: One input per row + selection scope**

1. Edit the campaign, switch to **Selection of products**: the items table appears, the percentage field hides.
2. In a row, choose **Fixed €** → only the € input shows; choose **% off** → only the % input shows; switching toggles live with no reload.
3. Tick one item, set a valid value, switch the campaign back to inactive if needed, Save: only that item is discounted on the storefront.

Expected: exactly one value input per row; selection discount applies only to ticked items.

- [ ] **Step 4: Blank value shows an error (no silent drop)**

1. Edit the selection campaign, tick an item, clear its value field, Save.
2. The form re-renders with an error like "`<item name>`: enter a price/percentage" and the item is **not** saved (re-open to confirm it stayed unticked).

Expected: a visible per-item error; nothing persisted on that save.

- [ ] **Step 5: Single active campaign is enforced**

1. With one campaign active, create or edit a second campaign and tick **Active**, Save.
2. Saving fails with "Another campaign is already active — deactivate it before activating this one." and the second campaign is not activated.

Expected: the block fires; only one campaign can be active.

- [ ] **Step 6: Full lint pass**

Run:
```bash
bin/rubocop
```
Expected: no new offenses from the changed files. Then stop the server: `kill $(lsof -ti :3000)`.
