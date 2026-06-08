# Nameable Variations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give each product variation an optional custom name that overrides its auto-generated attribute label everywhere it is displayed.

**Architecture:** Add a nullable `name` column to `variants`. `Variant#label` returns `name` when present, otherwise the existing attribute-value join (renamed `options_label`). Every display site already calls `variant.label`, so the override propagates for free. The admin variant form gains a name field; the controller persists it. Variation identity and duplicate detection stay attribute-based.

**Tech Stack:** Rails 8.1, SQLite, ERB views, Hotwire (no JS changes needed). No automated test suite — verification is `bin/rubocop` plus manual checks in the running app per `CLAUDE.md`.

---

### Task 1: Add `name` column to variants

**Files:**
- Create: `db/migrate/<timestamp>_add_name_to_variants.rb` (generated)
- Modify: `db/schema.rb` (auto-updated by migration)

- [ ] **Step 1: Generate the migration**

Run:
```bash
bin/rails generate migration AddNameToVariants name:string
```
Expected: a new file `db/migrate/<timestamp>_add_name_to_variants.rb` is created.

- [ ] **Step 2: Confirm the migration body**

Open the generated file. It should read exactly:
```ruby
class AddNameToVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :variants, :name, :string
  end
end
```
The column is nullable (no `null: false`, no default) — that is correct; name is optional. Leave it as generated.

- [ ] **Step 3: Run the migration**

Run:
```bash
bin/rails db:migrate
```
Expected: output shows `add_column(:variants, :name, :string)` and the migration completes. `db/schema.rb` now lists `t.string "name"` inside `create_table "variants"`.

- [ ] **Step 4: Commit**

```bash
git add db/migrate db/schema.rb
git commit -m "Add nullable name column to variants"
```

---

### Task 2: Make `Variant#label` prefer the custom name

**Files:**
- Modify: `app/models/variant.rb:11-16`

- [ ] **Step 1: Rename the existing join to `options_label` and add the override**

Replace the current `label` method (lines 11-16):
```ruby
  # "Large / Red", ordered by attribute position.
  def label
    variant_attribute_values
      .includes(:variant_attribute)
      .sort_by { |v| v.variant_attribute.position }
      .map(&:value).join(" / ")
  end
```
with:
```ruby
  # Custom name when set, otherwise the attribute combination.
  def label
    name.presence || options_label
  end

  # "Large / Red", ordered by attribute position.
  def options_label
    variant_attribute_values
      .includes(:variant_attribute)
      .sort_by { |v| v.variant_attribute.position }
      .map(&:value).join(" / ")
  end
```

- [ ] **Step 2: Verify in the console**

Run:
```bash
bin/rails runner '
  v = Variant.first
  puts "label=#{v.label.inspect} options_label=#{v.options_label.inspect}"
  v.name = "Studio second"
  puts "with name -> label=#{v.label.inspect}"
'
```
Expected: first line shows the attribute label for both (e.g. `label="Large / Red" options_label="Large / Red"`); second line shows `label="Studio second"`. (This does not save — it only checks the method.)

- [ ] **Step 3: Run the linter**

Run:
```bash
bin/rubocop app/models/variant.rb
```
Expected: no offenses.

- [ ] **Step 4: Commit**

```bash
git add app/models/variant.rb
git commit -m "Variant#label prefers custom name, falls back to options_label"
```

---

### Task 3: Persist `name` in the variants controller

**Files:**
- Modify: `app/controllers/admin/variants_controller.rb:10-20` (create), `:24-34` (update), private helpers

- [ ] **Step 1: Add a `variant_name` helper**

In the `private` section, next to `variant_price` (line 51-53), add:
```ruby
    def variant_name
      params.dig(:variant, :name).presence
    end
```
`.presence` coerces a blank submitted name to `nil` so an empty field clears the name.

- [ ] **Step 2: Set name on create**

In `create` (line 11), change:
```ruby
      @variant = @product.variants.new(price: variant_price)
```
to:
```ruby
      @variant = @product.variants.new(price: variant_price, name: variant_name)
```

- [ ] **Step 3: Set name on update**

In `update` (line 26), change:
```ruby
      if @variant.update(price: variant_price)
```
to:
```ruby
      if @variant.update(price: variant_price, name: variant_name)
```

- [ ] **Step 4: Run the linter**

Run:
```bash
bin/rubocop app/controllers/admin/variants_controller.rb
```
Expected: no offenses.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/admin/variants_controller.rb
git commit -m "Persist variation name on create and update"
```

---

### Task 4: Add the name field to the admin variant form

**Files:**
- Modify: `app/views/admin/variants/_form.html.erb:40-42` (insert the name field just before the Price field)

- [ ] **Step 1: Insert the name field**

In `_form.html.erb`, immediately before the Price field (currently line 40):
```erb
      <label class="field"><div class="field-label">Price (€)</div>
        <%= f.number_field :price, value: @variant.price, min: 0, class: "input" %>
      </label>
```
add this block above it:
```erb
      <label class="field"><div class="field-label">Name</div>
        <%= f.text_field :name, value: @variant.name, class: "input", placeholder: "e.g. Studio second" %>
        <div class="field-hint">Optional. Leave blank to use the attribute combination.</div>
      </label>
```

- [ ] **Step 2: Verify the form renders**

Start the server (`bin/rails server`), log into `/admin` (password: `studio`), open any product with attributes defined, and click to add/edit a variation. Confirm the "Name" field appears above Price with the hint text, and that editing an existing named variation pre-fills the field.

- [ ] **Step 3: Commit**

```bash
git add app/views/admin/variants/_form.html.erb
git commit -m "Add optional Name field to the variation form"
```

---

### Task 5: End-to-end manual verification

**Files:** none (verification only)

- [ ] **Step 1: Named variation shows everywhere**

With the server running and logged into `/admin`:
1. Create a variation, set Name to `Studio second`, pick an attribute combo, save.
2. Visit that product's storefront page. The variant picker chip should read `Studio second · <price>` (from `products/show.html.erb:61`).
3. Add it to the cart — the cart line tag should read `Studio second` (`shared/_cart_contents.html.erb:30`).
4. Go to checkout — the summary line should read `… · Studio second` (`checkout/new.html.erb:51`).

Expected: the custom name appears in all four places.

- [ ] **Step 2: Unnamed variation falls back**

1. Create a second variation with a different attribute combo and **no** name, save.
2. On the storefront, its picker chip should read the attribute label (e.g. `Large / Red · <price>`).

Expected: unnamed variation still shows the auto-generated attribute label.

- [ ] **Step 3: Clearing a name reverts**

1. Edit the `Studio second` variation, clear the Name field, save.
2. Reload the storefront product page.

Expected: that variation's chip now shows its attribute label instead of `Studio second`.

- [ ] **Step 4: Full lint pass**

Run:
```bash
bin/rubocop
```
Expected: no offenses.
