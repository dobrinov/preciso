# Catalogue & Storefront Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add product variations, collections, promotional campaigns, category/about images, more product photos, contacts/social links, and the cursive logo to the Preciso storefront + admin.

**Architecture:** Additive layers over the existing duck-typed `(kind, id)` catalogue. Simple products are untouched: variations, an active campaign, and collections only change behavior when present. A single campaign *pricing layer* (`current_price`) is introduced in Phase 3 and reused by variations in Phase 4. The cart's session-line shape gains an optional `variant_id`.

**Tech Stack:** Rails 8.1 / Ruby 4.0, SQLite, Active Storage (local disk, no variants), Hotwire (Turbo + Stimulus over importmap), Propshaft, hand-written `application.css`.

**Testing note:** This repo has **no automated test suite** (see `CLAUDE.md`). Each task is verified by exercising the admin + storefront flow described in its **Verify** step and running `bin/rubocop` (autocorrect with `bin/rubocop -a`) and, where models/controllers change, `bin/brakeman`. Do not write `test/` files — there is no framework wired up.

**Conventions:**
- Prices are integer euros (matching `Product#price`, `money` helper).
- Slugs that must stay stable mirror `Category#assign_slug` (regenerate only on name change).
- Admin controllers inherit `Admin::BaseController`; storefront inherit `ApplicationController`.
- Run `bin/rails db:migrate` after each migration step. Generate migrations with `bin/rails g migration NAME` (so the timestamp is real), then paste the provided body into the generated file.

---

## File Structure

**Phase 1 — Quick wins**
- Create: `app/assets/images/preciso-logo.jpg`
- Modify: `app/views/shared/_header.html.erb`, `app/views/shared/_footer.html.erb`, `app/helpers/icons_helper.rb`
- Modify: `app/models/category.rb` *(none needed)*, `app/controllers/admin/categories_controller.rb`, `app/views/admin/categories/_form.html.erb`, `app/views/home/index.html.erb`, `app/views/shop/show.html.erb`
- Modify: `app/models/about.rb` *(attachment)*, `app/controllers/admin/about_controller.rb`, `app/views/admin/about/edit.html.erb`, `app/views/pages/about.html.erb`
- Modify: `app/javascript/controllers/multiupload_controller.js`

**Phase 2 — Collections**
- Create: migration, `app/models/collection.rb`, `app/models/collection_membership.rb`, `app/controllers/admin/collections_controller.rb`, `app/views/admin/collections/{index,new,edit,_form}.html.erb`, `app/controllers/collections_controller.rb`, `app/views/collections/show.html.erb`
- Modify: `config/routes.rb`, `app/models/product.rb`, `app/views/admin/shared/_sidebar.html.erb`, `app/views/shared/_header.html.erb`, `app/views/shared/_footer.html.erb`, `db/seeds.rb`

**Phase 3 — Campaigns**
- Create: migration, `app/models/campaign.rb`, `app/models/campaign_item.rb`, `app/controllers/admin/campaigns_controller.rb`, `app/views/admin/campaigns/{index,new,edit,_form}.html.erb`, `app/controllers/campaigns_controller.rb`, `app/views/campaigns/show.html.erb`, `app/views/shared/_campaign_banner.html.erb`
- Modify: `config/routes.rb`, `app/models/product.rb`, `app/models/product_set.rb`, `app/models/cart.rb`, `app/controllers/checkout_controller.rb`, `app/views/shared/_product_card.html.erb`, `app/views/products/show.html.erb`, `app/views/shared/_cart_contents.html.erb`, `app/views/home/index.html.erb`, `app/controllers/home_controller.rb`, `app/views/admin/shared/_sidebar.html.erb`

**Phase 4 — Variations**
- Create: migration, `app/models/variant_attribute.rb`, `app/models/variant_attribute_value.rb`, `app/models/variant.rb`, `app/models/variant_value.rb`, `app/controllers/admin/variant_attributes_controller.rb`, `app/controllers/admin/variants_controller.rb`, `app/views/admin/variant_attributes/{index,new,edit,_form}.html.erb`, `app/views/admin/variants/{new,edit,_form}.html.erb`, `app/javascript/controllers/variants_controller.js`
- Modify: migration for `order_lines`, `config/routes.rb`, `app/models/product.rb`, `app/models/order_line.rb`, `app/models/cart.rb`, `app/controllers/cart_controller.rb`, `app/controllers/checkout_controller.rb`, `app/views/admin/products/_form.html.erb`, `app/views/products/show.html.erb`, `app/views/shared/_product_card.html.erb`, `app/views/shared/_cart_contents.html.erb`, `app/views/cart/*.turbo_stream.erb`, `app/views/admin/shared/_sidebar.html.erb`

---

# Phase 1 — Quick Wins

### Task 1: Cursive logo in header & footer

**Files:**
- Create: `app/assets/images/preciso-logo.jpg` (copy of `/Users/deyan.dobrinov/Desktop/logo.jpg`)
- Modify: `app/views/shared/_header.html.erb`, `app/views/shared/_footer.html.erb`

- [ ] **Step 1: Copy the logo asset into the repo**

```bash
cp /Users/deyan.dobrinov/Desktop/logo.jpg app/assets/images/preciso-logo.jpg
```

- [ ] **Step 2: Use the logo in the header brand**

In `app/views/shared/_header.html.erb`, replace the `<a ... class="brand">…</a>` block with:

```erb
    <a href="<%= root_path %>" class="brand">
      <%= image_tag "preciso-logo.jpg", alt: "Preciso", class: "brand-logo" %>
      <span class="brand-sub">Porcelain Studio</span>
    </a>
```

- [ ] **Step 3: Use the logo in the footer brand**

In `app/views/shared/_footer.html.erb`, replace `<div class="foot-brand">Preciso</div>` with:

```erb
        <%= image_tag "preciso-logo.jpg", alt: "Preciso", class: "foot-logo" %>
```

- [ ] **Step 4: Add sizing CSS**

Append to `app/assets/stylesheets/application.css`:

```css
.brand-logo { height: 30px; width: auto; display: block; }
.foot-logo { height: 34px; width: auto; margin-bottom: 14px; }
```

- [ ] **Step 5: Verify**

Run `bin/rails server`, open `http://localhost:3000`. The cursive "Preciso" appears in the header and footer; clicking it returns home. Check a narrow viewport — the logo scales, not overflows.

- [ ] **Step 6: Commit**

```bash
git add app/assets/images/preciso-logo.jpg app/views/shared/_header.html.erb app/views/shared/_footer.html.erb app/assets/stylesheets/application.css
git commit -m "Use cursive Preciso logo in header and footer"
```

---

### Task 2: Category image upload

**Files:**
- Modify: `app/models/category.rb`, `app/controllers/admin/categories_controller.rb`, `app/views/admin/categories/_form.html.erb`, `app/views/home/index.html.erb`, `app/views/shop/show.html.erb`

- [ ] **Step 1: Attach an image to Category**

In `app/models/category.rb`, add below `has_many :products, dependent: :nullify`:

```ruby
  has_one_attached :image
```

- [ ] **Step 2: Permit the image param**

In `app/controllers/admin/categories_controller.rb`, change `category_params` to:

```ruby
    def category_params
      params.require(:category).permit(:name, :blurb, :tone, :image)
    end
```

Then add image removal handling — replace `update` with:

```ruby
    def update
      if @category.update(category_params)
        @category.image.purge if params.dig(:category, :remove_image) == "1"
        redirect_to admin_categories_path
      else
        render :edit, status: :unprocessable_entity
      end
    end
```

- [ ] **Step 3: Add the upload field to the category form**

In `app/views/admin/categories/_form.html.erb`, change the opening tag to multipart:

```erb
<%= form_with model: [:admin, @category], html: { multipart: true } do |f| %>
```

Then, inside the right-hand `<div class="stack-18">`, **above** the existing `data-controller="tone"` box, add:

```erb
      <div class="box" data-controller="imageupload">
        <div class="box-label">Category image</div>
        <div class="dropzone" data-imageupload-target="zone" data-action="click->imageupload#browse dragover->imageupload#dragover dragleave->imageupload#dragleave drop->imageupload#drop">
          <% if @category.image.attached? %>
            <%= image_tag @category.image, data: { imageupload_target: "preview" } %>
          <% else %>
            <div data-imageupload-target="placeholder"><%= placeholder(tone: @category.tone, name: @category.name.presence || "Category", caption: "click or drop photo") %></div>
            <img data-imageupload-target="preview" style="display:none">
          <% end %>
        </div>
        <%= f.file_field :image, accept: "image/*", style: "display:none", data: { imageupload_target: "input", action: "imageupload#changed" } %>
        <%= hidden_field_tag "category[remove_image]", "0", data: { imageupload_target: "removeFlag" } %>
        <div class="dropzone-actions">
          <button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#browse">Upload</button>
          <% if @category.image.attached? %>
            <button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#remove">Remove</button>
          <% end %>
        </div>
      </div>
```

(The `imageupload` Stimulus controller already exists — it's used by the set form.)

- [ ] **Step 4: Show the image on the home category tiles**

In `app/views/home/index.html.erb`, inside the `cat-frame` div, replace the `<%= placeholder(tone: c.tone, caption: "category · #{count} pieces") %>` line with:

```erb
            <% if c.image.attached? %>
              <%= image_tag c.image, alt: c.name, class: "cover-img" %>
            <% else %>
              <%= placeholder(tone: c.tone, caption: "category · #{count} pieces") %>
            <% end %>
```

- [ ] **Step 5: Show the image on the shop category header**

In `app/views/shop/show.html.erb`, immediately after the `render "shared/catnav"` line, add:

```erb
  <% if @category.image.attached? %>
    <div class="ratio-box img-frame shop-hero" style="padding-top:36%">
      <%= image_tag @category.image, alt: @category.name, class: "cover-img" %>
    </div>
  <% end %>
```

Append CSS to `app/assets/stylesheets/application.css`:

```css
.shop-hero { border-radius: 14px; overflow: hidden; margin: 6px 0 30px; }
```

- [ ] **Step 6: Verify**

Restart the server. In `/admin/categories`, edit a category, upload an image, save. The home tile and `/shop/<slug>` header now show the photo; categories without an image still show the color placeholder. Re-edit and click Remove → placeholder returns.

- [ ] **Step 7: Lint & commit**

```bash
bin/rubocop -a app/models/category.rb app/controllers/admin/categories_controller.rb
git add -A
git commit -m "Add category image upload and display"
```

---

### Task 3: About page image

**Files:**
- Modify: `app/models/about.rb`, `app/controllers/admin/about_controller.rb`, `app/views/admin/about/edit.html.erb`, `app/views/pages/about.html.erb`

- [ ] **Step 1: Attach an image to About**

In `app/models/about.rb`, add below the `serialize` line:

```ruby
  has_one_attached :image
```

- [ ] **Step 2: Handle the upload in the controller**

In `app/controllers/admin/about_controller.rb`, inside `update`, after the `@about.update(...)` call and before the redirect, add:

```ruby
      @about.image.attach(params[:image]) if params[:image].present?
      @about.image.purge if params[:remove_image] == "1"
```

- [ ] **Step 3: Add a file field to the About form**

In `app/views/admin/about/edit.html.erb`, make the form multipart — change the opening `form_with` to:

```erb
<%= form_with url: admin_about_path, method: :patch, html: { multipart: true }, data: { controller: "abouteditor imageupload", turbo: false } do %>
```

Then, immediately **above** the `<div style="display:grid;grid-template-columns:1fr 1fr;gap:18px">` (signature/studio row), add:

```erb
      <div class="field">
        <div class="field-label">Studio photograph</div>
        <div class="dropzone" data-imageupload-target="zone" data-action="click->imageupload#browse dragover->imageupload#dragover dragleave->imageupload#dragleave drop->imageupload#drop" style="max-width:340px">
          <% if @about.image.attached? %>
            <%= image_tag @about.image, data: { imageupload_target: "preview" } %>
          <% else %>
            <div data-imageupload-target="placeholder"><%= placeholder(tone: "#ebe5dc", name: "Studio", caption: "click or drop photo") %></div>
            <img data-imageupload-target="preview" style="display:none">
          <% end %>
        </div>
        <%= file_field_tag :image, accept: "image/*", style: "display:none", data: { imageupload_target: "input", action: "imageupload#changed" } %>
        <%= hidden_field_tag :remove_image, "0", data: { imageupload_target: "removeFlag" } %>
        <div class="dropzone-actions" style="max-width:340px">
          <button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#browse">Upload</button>
          <% if @about.image.attached? %>
            <button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#remove">Remove</button>
          <% end %>
        </div>
      </div>
```

- [ ] **Step 4: Show the image on the storefront About page**

In `app/views/pages/about.html.erb`, replace the `about-figure` block:

```erb
    <div class="about-figure"><%= placeholder(tone: "#ebe5dc", caption: "studio photograph", name: "The studio") %></div>
```

with:

```erb
    <div class="about-figure">
      <% if @about.image.attached? %>
        <%= image_tag @about.image, alt: "Studio", class: "cover-img" %>
      <% else %>
        <%= placeholder(tone: "#ebe5dc", caption: "studio photograph", name: "The studio") %>
      <% end %>
    </div>
```

- [ ] **Step 5: Verify**

Restart the server. In `/admin/about`, upload a photo, Save. `/about` shows it. Remove → placeholder returns.

- [ ] **Step 6: Lint & commit**

```bash
bin/rubocop -a app/models/about.rb app/controllers/admin/about_controller.rb
git add -A
git commit -m "Add About page image upload and display"
```

---

### Task 4: Contacts & social links

**Files:**
- Modify: `app/helpers/icons_helper.rb`, `app/views/shared/_footer.html.erb`, `app/views/pages/about.html.erb`

- [ ] **Step 1: Add Instagram & Facebook icons**

In `app/helpers/icons_helper.rb`, add these two entries inside the `ICONS = { … }` hash (after the `tag:` line):

```ruby
    instagram: %(<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.2" cy="6.8" r="1"/>),
    facebook:  %(<path d="M14 8h2V5h-2a3 3 0 0 0-3 3v2H9v3h2v6h3v-6h2.2l.4-3H14v-1.6c0-.5.2-.4.6-.4Z"/>),
```

- [ ] **Step 2: Add contact + social to the footer**

In `app/views/shared/_footer.html.erb`, replace the entire `<div>` that contains the "Studio" eyebrow (the third `foot-col`) with:

```erb
      <div>
        <div class="eyebrow">Studio</div>
        <div class="foot-col-list">
          <a href="<%= about_path %>" class="foot-link">About Bianna</a>
          <a href="<%= admin_login_path %>" class="foot-link">Studio login</a>
        </div>
      </div>
      <div>
        <div class="eyebrow">Contact</div>
        <div class="foot-contact">
          <div class="foot-contact-name">Bianna Taynova</div>
          <a href="tel:+359885448888" class="foot-link">+359 88 544 8888</a>
          <div class="foot-addr">Sofia, Vitosha blvd. 200, section A</div>
          <div class="foot-social">
            <a href="https://www.instagram.com/preciso_handmade/" target="_blank" rel="noopener" aria-label="Instagram"><%= icon :instagram, size: 20 %></a>
            <a href="https://www.facebook.com/PrecisoHandmade" target="_blank" rel="noopener" aria-label="Facebook"><%= icon :facebook, size: 20 %></a>
          </div>
        </div>
      </div>
```

- [ ] **Step 3: Add a contact block to the About page**

In `app/views/pages/about.html.erb`, inside the final `<div class="about-cta">`, after the `<a … Browse the shop …>` link, add:

```erb
      <div class="about-contact">
        <div class="about-contact-name">Bianna Taynova</div>
        <a href="tel:+359885448888">+359 88 544 8888</a>
        <div>Sofia, Vitosha blvd. 200, section A</div>
        <div class="foot-social" style="justify-content:center;margin-top:12px">
          <a href="https://www.instagram.com/preciso_handmade/" target="_blank" rel="noopener" aria-label="Instagram"><%= icon :instagram, size: 22 %></a>
          <a href="https://www.facebook.com/PrecisoHandmade" target="_blank" rel="noopener" aria-label="Facebook"><%= icon :facebook, size: 22 %></a>
        </div>
      </div>
```

- [ ] **Step 4: Add CSS**

Append to `app/assets/stylesheets/application.css`:

```css
.foot-contact { display: flex; flex-direction: column; gap: 6px; font-size: 13px; color: var(--muted); }
.foot-contact-name { color: var(--ink); }
.foot-addr { line-height: 1.4; }
.foot-social { display: flex; gap: 14px; margin-top: 10px; }
.foot-social a { color: var(--muted); }
.foot-social a:hover { color: var(--ink); }
.about-contact { margin-top: 34px; font-size: 15px; color: var(--muted); display: flex; flex-direction: column; gap: 4px; }
.about-contact-name { color: var(--ink); font-size: 17px; }
```

- [ ] **Step 5: Verify**

Restart the server. The footer (every page) shows the name, a tappable phone link, the address, and Instagram/Facebook icons that open the correct profiles in a new tab. `/about` shows the contact block.

- [ ] **Step 6: Lint & commit**

```bash
bin/rubocop -a app/helpers/icons_helper.rb
git add -A
git commit -m "Expose studio contacts and Instagram/Facebook links"
```

---

### Task 5: Allow many product photos (accumulating uploader)

**Files:**
- Modify: `app/javascript/controllers/multiupload_controller.js`

**Context:** No server-side cap exists — `attach_images` attaches all files and appends on each save. The practical limit is that each "Add photos" click *replaces* the file input's selection, so a user can't build up a selection across clicks before saving. Make the uploader **accumulate** selected files so many photos can be added in one edit.

- [ ] **Step 1: Reproduce the limitation**

Run the server, open `/admin/products/new`, click "Add photos", pick 1 file, click "Add photos" again, pick another → only the second is kept. Confirm.

- [ ] **Step 2: Make selections accumulate**

Replace the entire body of `app/javascript/controllers/multiupload_controller.js` with:

```js
import { Controller } from "@hotwired/stimulus"

// Multi-photo upload: accumulate newly selected files across clicks/drops,
// preview them, and mark existing attachments for removal.
export default class extends Controller {
  static targets = ["input", "zone", "placeholder", "previews"]

  connect() {
    this.buffer = new DataTransfer()
  }

  browse(e) {
    e?.preventDefault()
    this.inputTarget.click()
  }

  changed() {
    this.absorb(this.inputTarget.files)
  }

  dragover(e) {
    e.preventDefault()
    this.zoneTarget.classList.add("drag")
  }

  dragleave() {
    this.zoneTarget.classList.remove("drag")
  }

  drop(e) {
    e.preventDefault()
    this.zoneTarget.classList.remove("drag")
    if (!e.dataTransfer.files.length) return
    this.absorb(e.dataTransfer.files)
  }

  // Append the given files to the buffer, then write the buffer back to the
  // real input so all of them submit with the form.
  absorb(files) {
    Array.from(files).forEach((f) => this.buffer.items.add(f))
    this.inputTarget.files = this.buffer.files
    this.renderPreviews(this.buffer.files)
  }

  renderPreviews(files) {
    this.previewsTarget.innerHTML = ""
    if (!files || !files.length) {
      this.previewsTarget.style.display = "none"
      this.placeholderTarget.style.display = "block"
      return
    }
    this.placeholderTarget.style.display = "none"
    this.previewsTarget.style.display = "grid"
    Array.from(files).forEach((file) => {
      const reader = new FileReader()
      const tile = document.createElement("div")
      tile.className = "img-tile"
      reader.onload = () => {
        tile.innerHTML = `<img class="cover-img" src="${reader.result}">`
      }
      reader.readAsDataURL(file)
      this.previewsTarget.appendChild(tile)
    })
  }

  toggleRemove(e) {
    const tile = e.currentTarget.closest(".img-tile")
    const cb = tile.querySelector(".img-remove-cb")
    cb.checked = !cb.checked
    tile.classList.toggle("marked", cb.checked)
  }
}
```

- [ ] **Step 3: Verify**

Restart the server. On `/admin/products/new`, add photos in several separate clicks → all previews accumulate. Fill name + price, save. Edit the product → all photos are attached. Add 3 more on edit → 5+ total attached. Drag-drop also appends.

- [ ] **Step 4: Commit**

```bash
git add app/javascript/controllers/multiupload_controller.js
git commit -m "Accumulate product photo selections so many can be added at once"
```

---

# Phase 2 — Collections

### Task 6: Collection models & migration

**Files:**
- Create: migration, `app/models/collection.rb`, `app/models/collection_membership.rb`
- Modify: `app/models/product.rb`

- [ ] **Step 1: Generate the migration**

```bash
bin/rails g migration CreateCollections
```

Replace the generated file's body with:

```ruby
class CreateCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :collections do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, default: 0
      t.timestamps
    end
    add_index :collections, :slug, unique: true

    create_table :collection_memberships do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :position, default: 0
      t.timestamps
    end
    add_index :collection_memberships, [:collection_id, :product_id], unique: true
  end
end
```

- [ ] **Step 2: Migrate**

```bash
bin/rails db:migrate
```

Expected: both tables created; `db/schema.rb` updated.

- [ ] **Step 3: Create the join model**

Create `app/models/collection_membership.rb`:

```ruby
class CollectionMembership < ApplicationRecord
  belongs_to :collection
  belongs_to :product
end
```

- [ ] **Step 4: Create the Collection model**

Create `app/models/collection.rb` (slug logic mirrors `Category`):

```ruby
class Collection < ApplicationRecord
  has_one_attached :cover
  has_many :collection_memberships, -> { order(:position) }, dependent: :destroy
  has_many :products, through: :collection_memberships

  default_scope { order(:position) }
  scope :nonempty, -> { joins(:collection_memberships).distinct }

  before_validation :assign_slug
  before_create :assign_position

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param = slug

  private

  def assign_slug
    if new_record?
      self.slug = generate_slug if slug.blank?
    elsif name_changed?
      self.slug = generate_slug
    end
  end

  def generate_slug
    base = name.to_s.parameterize.presence || "collection"
    candidate = base
    i = 2
    while Collection.unscoped.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{i}"
      i += 1
    end
    candidate
  end

  def assign_position
    self.position = (Collection.unscoped.maximum(:position) || -1) + 1
  end
end
```

- [ ] **Step 5: Wire products to collections**

In `app/models/product.rb`, add below `has_many :set_items, dependent: :destroy`:

```ruby
  has_many :collection_memberships, dependent: :destroy
  has_many :collections, through: :collection_memberships
```

- [ ] **Step 6: Verify in console**

```bash
bin/rails runner 'c = Collection.create!(name: "Oro"); c.products << Product.first; puts c.reload.slug; puts c.products.count'
```

Expected: prints `oro` and `1`. Then clean up: `bin/rails runner 'Collection.find_by(slug: "oro")&.destroy'`.

- [ ] **Step 7: Lint & commit**

```bash
bin/rubocop -a app/models/collection.rb app/models/collection_membership.rb app/models/product.rb
git add -A
git commit -m "Add Collection model with product memberships"
```

---

### Task 7: Collections admin CRUD

**Files:**
- Create: `app/controllers/admin/collections_controller.rb`, `app/views/admin/collections/{index,new,edit,_form}.html.erb`
- Modify: `config/routes.rb`, `app/views/admin/shared/_sidebar.html.erb`

- [ ] **Step 1: Add the route**

In `config/routes.rb`, inside `namespace :admin`, after `resources :sets, controller: "product_sets"`, add:

```ruby
    resources :collections
```

- [ ] **Step 2: Add the sidebar link**

In `app/views/admin/shared/_sidebar.html.erb`, add to the `active` case (after the `product_sets` line):

```ruby
           when "collections" then "collections"
```

and add to the `nav` array (after the `sets` row):

```ruby
    ["collections", "Collections", :layers, admin_collections_path],
```

- [ ] **Step 3: Create the controller**

Create `app/controllers/admin/collections_controller.rb`:

```ruby
module Admin
  class CollectionsController < BaseController
    before_action :set_collection, only: [:edit, :update, :destroy]

    def index
      @collections = Collection.all
    end

    def new
      @collection = Collection.new
    end

    def create
      @collection = Collection.new(collection_params)
      if @collection.save
        rebuild_members(@collection)
        attach_cover(@collection)
        redirect_to admin_collections_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @collection.update(collection_params)
        rebuild_members(@collection)
        attach_cover(@collection)
        @collection.cover.purge if params.dig(:collection, :remove_cover) == "1"
        redirect_to admin_collections_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @collection.destroy
      redirect_to admin_collections_path
    end

    private

    def set_collection
      @collection = Collection.find(params[:id])
    end

    def collection_params
      params.require(:collection).permit(:name, :description)
    end

    def rebuild_members(collection)
      ids = Array(params.dig(:collection, :product_ids)).reject(&:blank?).uniq
      collection.collection_memberships.destroy_all
      ids.each_with_index do |pid, i|
        next unless Product.exists?(pid)
        collection.collection_memberships.create!(product_id: pid, position: i)
      end
    end

    def attach_cover(collection)
      collection.cover.attach(params[:collection][:cover]) if params.dig(:collection, :cover).present?
    end
  end
end
```

- [ ] **Step 4: Create the index view**

Create `app/views/admin/collections/index.html.erb`:

```erb
<% content_for :title, "Preciso — Collections" %>
<div class="pagehead">
  <div>
    <h1 class="display pagehead-title">Collections</h1>
    <p class="pagehead-sub">Groups of pieces that share a style.</p>
  </div>
  <div class="pagehead-actions">
    <a href="<%= new_admin_collection_path %>" class="btn clay sm"><%= icon :plus, size: 16 %> New collection</a>
  </div>
</div>
<div class="admin-pad">
  <% if @collections.empty? %>
    <div class="empty-state">No collections yet.</div>
  <% else %>
    <div class="admin-list">
      <% @collections.each do |c| %>
        <a href="<%= edit_admin_collection_path(c) %>" class="admin-row">
          <div class="admin-row-thumb">
            <% if c.cover.attached? %><%= image_tag c.cover, class: "cover-img" %><% else %><%= placeholder(tone: "#ece6dd", name: c.name) %><% end %>
          </div>
          <div class="admin-row-main">
            <div class="admin-row-name"><%= c.name %></div>
            <div class="admin-row-sub"><%= c.products.count %> pieces · /collection/<%= c.slug %></div>
          </div>
          <span class="admin-row-go"><%= icon :arrow, size: 16 %></span>
        </a>
      <% end %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 5: Create new/edit wrappers**

Create `app/views/admin/collections/new.html.erb`:

```erb
<% content_for :title, "Preciso — New collection" %>
<%= render "form" %>
```

Create `app/views/admin/collections/edit.html.erb`:

```erb
<% content_for :title, "Preciso — Edit collection" %>
<%= render "form" %>
```

- [ ] **Step 6: Create the form partial**

Create `app/views/admin/collections/_form.html.erb`:

```erb
<% is_new = @collection.new_record? %>
<%
  products = Product.includes(:category).order(:id)
  selected_ids = @collection.product_ids
%>
<div class="pagehead">
  <div>
    <h1 class="display pagehead-title"><%= is_new ? "New collection" : (@collection.name.presence || "Edit collection") %></h1>
    <p class="pagehead-sub">Pick the pieces that belong to this style.</p>
  </div>
  <div class="pagehead-actions">
    <a href="<%= admin_collections_path %>" class="btn ghost sm"><%= icon :back, size: 16 %> Back</a>
  </div>
</div>

<%= form_with model: [:admin, @collection], html: { multipart: true } do |f| %>
  <div class="admin-pad editor-grid" style="align-items:start">
    <div class="card-pad">
      <% if @collection.errors.any? %>
        <div class="login-err"><%= @collection.errors.full_messages.to_sentence %></div>
      <% end %>
      <label class="field"><div class="field-label">Name</div>
        <%= f.text_field :name, class: "input", placeholder: "e.g. Oro" %>
        <% unless is_new %><div class="field-hint">URL: <span class="mono">/collection/<%= @collection.slug %></span></div><% end %>
      </label>
      <label class="field"><div class="field-label">Description</div>
        <%= f.text_area :description, rows: 3, class: "input", placeholder: "What ties these pieces together." %>
      </label>

      <div class="field">
        <div class="field-label">Pieces in this collection</div>
        <div class="piece-picker">
          <% products.each do |p| %>
            <label class="piece-btn" style="cursor:pointer">
              <%= check_box_tag "collection[product_ids][]", p.id, selected_ids.include?(p.id), style: "margin-right:8px" %>
              <div class="thumb"><%= media_for(p, kind: "product", cover: true) %></div>
              <div style="min-width:0">
                <div class="pname"><%= p.name %></div>
                <div class="pprice"><%= p.category&.name %></div>
              </div>
            </label>
          <% end %>
        </div>
        <%= hidden_field_tag "collection[product_ids][]", "" %>
      </div>
    </div>

    <div class="stack-18">
      <div class="box" data-controller="imageupload">
        <div class="box-label">Cover image</div>
        <div class="dropzone" data-imageupload-target="zone" data-action="click->imageupload#browse dragover->imageupload#dragover dragleave->imageupload#dragleave drop->imageupload#drop">
          <% if @collection.cover.attached? %>
            <%= image_tag @collection.cover, data: { imageupload_target: "preview" } %>
          <% else %>
            <div data-imageupload-target="placeholder"><%= placeholder(tone: "#ece6dd", name: @collection.name.presence || "Collection", caption: "click or drop photo") %></div>
            <img data-imageupload-target="preview" style="display:none">
          <% end %>
        </div>
        <%= f.file_field :cover, accept: "image/*", style: "display:none", data: { imageupload_target: "input", action: "imageupload#changed" } %>
        <%= hidden_field_tag "collection[remove_cover]", "0", data: { imageupload_target: "removeFlag" } %>
        <div class="dropzone-actions">
          <button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#browse">Upload</button>
          <% if @collection.cover.attached? %>
            <button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#remove">Remove</button>
          <% end %>
        </div>
      </div>

      <div class="box" style="display:flex;flex-direction:column;gap:12px">
        <%= f.submit (is_new ? "Create collection" : "Save changes"), class: "btn clay" %>
        <% unless is_new %>
          <%= button_to admin_collection_path(@collection), method: :delete, class: "danger-btn",
                form: { data: { turbo_confirm: "Delete this collection? The pieces stay in the shop." } } do %>
            <%= icon :trash, size: 16 %> Delete collection
          <% end %>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

(The hidden empty `product_ids[]` field ensures deselecting all still submits an empty array so `rebuild_members` clears them.)

- [ ] **Step 7: Verify**

Restart the server. `/admin/collections` → New → name "Oro", tick a few products, upload a cover, Create. The row shows the count and slug. Edit, untick one, save → count drops. Editing the name changes the slug shown.

- [ ] **Step 8: Lint & commit**

```bash
bin/rubocop -a app/controllers/admin/collections_controller.rb
git add -A
git commit -m "Add Collections admin CRUD with product picker"
```

---

### Task 8: Collections storefront page & navigation

**Files:**
- Create: `app/controllers/collections_controller.rb`, `app/views/collections/show.html.erb`
- Modify: `config/routes.rb`, `app/views/shared/_header.html.erb`, `app/views/shared/_footer.html.erb`, `db/seeds.rb`

- [ ] **Step 1: Add the storefront route**

In `config/routes.rb`, in the storefront section (after the `sets` routes), add:

```ruby
  get "collections", to: "collections#index", as: :collections
  get "collection/:slug", to: "collections#show", as: :collection
```

- [ ] **Step 2: Create the controller**

Create `app/controllers/collections_controller.rb`:

```ruby
class CollectionsController < ApplicationController
  def index
    @collections = Collection.nonempty
    track("collections", "Collections")
  end

  def show
    @collection = Collection.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @collection

    @products = @collection.products.order(:id)
    track("collection/#{@collection.slug}", "Collection · #{@collection.name}")
  end
end
```

- [ ] **Step 3: Create the show view**

Create `app/views/collections/show.html.erb`:

```erb
<% content_for :title, "Preciso — #{@collection.name}" %>
<main class="wrap fade-up page-top">
  <%= render "shared/breadcrumb", trail: [["Collections", collections_path], [@collection.name, nil]] %>
  <div class="list-head">
    <div>
      <div class="eyebrow clay">Collection</div>
      <h1 class="display list-title"><%= @collection.name %></h1>
      <p class="list-blurb"><%= @collection.description %></p>
    </div>
    <div class="list-count"><%= @products.size %> pieces</div>
  </div>

  <% if @collection.cover.attached? %>
    <div class="ratio-box img-frame shop-hero" style="padding-top:34%">
      <%= image_tag @collection.cover, alt: @collection.name, class: "cover-img" %>
    </div>
  <% end %>

  <% if @products.empty? %>
    <div class="empty-state">No pieces in this collection yet.</div>
  <% else %>
    <div class="grid-3 shop-grid">
      <% @products.each do |p| %>
        <%= render "shared/product_card", record: p, kind: "product" %>
      <% end %>
    </div>
  <% end %>
</main>
```

- [ ] **Step 4: Create a simple collections index view**

Create `app/views/collections/index.html.erb`:

```erb
<% content_for :title, "Preciso — Collections" %>
<main class="wrap fade-up page-top">
  <%= render "shared/breadcrumb", trail: [["Collections", nil]] %>
  <div class="list-head"><div><h1 class="display list-title">Collections</h1><p class="list-blurb">Pieces grouped by style.</p></div></div>
  <% if @collections.empty? %>
    <div class="empty-state">No collections yet.</div>
  <% else %>
    <div class="cat-grid">
      <% @collections.each do |c| %>
        <a href="<%= collection_path(c.slug) %>" class="cat-tile">
          <div class="cat-frame square">
            <% if c.cover.attached? %><%= image_tag c.cover, alt: c.name, class: "cover-img" %><% else %><%= placeholder(tone: "#ece6dd", caption: "collection") %><% end %>
            <div class="cat-overlay"><div><div class="cat-name"><%= c.name %></div><div class="cat-blurb"><%= c.products.count %> pieces</div></div><span class="cat-arrow"><%= icon :arrow, size: 16 %></span></div>
          </div>
        </a>
      <% end %>
    </div>
  <% end %>
</main>
```

- [ ] **Step 5: Add Collections to nav & footer (only when some exist)**

In `app/views/shared/_header.html.erb`, in BOTH the `desk-nav` and `mob-nav` blocks, add after the Sets link:

```erb
      <% if Collection.nonempty.any? %><a href="<%= collections_path %>" class="navlink">Collections</a><% end %>
```

(In `mob-nav`, drop the `class="navlink"`.)

In `app/views/shared/_footer.html.erb`, inside the "Shop" `foot-col-list`, after the Sets link, add:

```erb
          <% if Collection.nonempty.any? %><a href="<%= collections_path %>" class="foot-link">Collections</a><% end %>
```

- [ ] **Step 6: Seed an example collection**

Append to `db/seeds.rb`:

```ruby
# ---- example collection (style group) ----
oro = Collection.find_or_create_by!(slug: "oro") { |c| c.name = "Oro"; c.description = "Pieces finished with a warm, golden cast." }
oro.products = Product.where(category: cat["vases"]).limit(2) + Product.where(category: cat["cups"]).limit(1)
```

- [ ] **Step 7: Verify**

```bash
bin/rails db:seed
bin/rails server
```

Open `/collection/oro` → header + the seeded products render. "Collections" appears in the top nav and footer. An unknown slug (`/collection/nope`) renders the not-found page. Visit `/collections` → tile grid.

- [ ] **Step 8: Lint & commit**

```bash
bin/rubocop -a app/controllers/collections_controller.rb
git add -A
git commit -m "Add Collections storefront pages, nav links, and seed"
```

---

# Phase 3 — Campaigns

### Task 9: Campaign models, migration & pricing layer

**Files:**
- Create: migration, `app/models/campaign.rb`, `app/models/campaign_item.rb`
- Modify: `app/models/product.rb`, `app/models/product_set.rb`

- [ ] **Step 1: Generate the migration**

```bash
bin/rails g migration CreateCampaigns
```

Replace the body with:

```ruby
class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :active, null: false, default: false
      t.text :blurb
      t.timestamps
    end
    add_index :campaigns, :slug, unique: true
    add_index :campaigns, :active

    create_table :campaign_items do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :kind, null: false, default: "product"
      t.integer :item_id, null: false
      t.string :discount_kind, null: false, default: "fixed"
      t.integer :sale_price
      t.integer :percent_off
      t.timestamps
    end
    add_index :campaign_items, [:kind, :item_id]
  end
end
```

- [ ] **Step 2: Migrate**

```bash
bin/rails db:migrate
```

- [ ] **Step 3: Create CampaignItem**

Create `app/models/campaign_item.rb`:

```ruby
class CampaignItem < ApplicationRecord
  belongs_to :campaign

  KINDS = %w[product set].freeze
  DISCOUNT_KINDS = %w[fixed percent].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :discount_kind, inclusion: { in: DISCOUNT_KINDS }
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :percent_off, numericality: { in: 1..99 }, allow_nil: true

  # The discounted price for a given base (integer €).
  def price_for(base)
    case discount_kind
    when "percent" then (base * (100 - percent_off.to_i) / 100.0).round
    else [sale_price.to_i, base].min
    end
  end

  # Resolve the catalogue record this item points at.
  def record
    kind == "set" ? ProductSet.find_by(id: item_id) : Product.find_by(id: item_id)
  end
end
```

- [ ] **Step 4: Create Campaign (with the central discount lookup)**

Create `app/models/campaign.rb`:

```ruby
class Campaign < ApplicationRecord
  has_one_attached :banner
  has_many :campaign_items, dependent: :destroy

  default_scope { order(:id) }
  scope :active, -> { where(active: true) }

  before_validation :assign_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param = slug

  # The active discount for a catalogue item, or nil. First active campaign wins.
  def self.discount_for(kind, id)
    CampaignItem.joins(:campaign)
                .where(campaigns: { active: true }, kind: kind.to_s, item_id: id)
                .order("campaigns.id")
                .first
  end

  private

  def assign_slug
    if new_record?
      self.slug = generate_slug if slug.blank?
    elsif name_changed?
      self.slug = generate_slug
    end
  end

  def generate_slug
    base = name.to_s.parameterize.presence || "campaign"
    candidate = base
    i = 2
    while Campaign.unscoped.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{i}"
      i += 1
    end
    candidate
  end
end
```

- [ ] **Step 5: Add `current_price` to Product and ProductSet**

In `app/models/product.rb`, add these methods (the `variant:` keyword is unused until Phase 4 but defined now so the cart can call it uniformly):

```ruby
  # Base price, optionally for a specific variant (Phase 4).
  def base_price(variant: nil)
    variant ? variant.price : price
  end

  # Price after any active campaign discount.
  def current_price(variant: nil)
    base = base_price(variant: variant)
    ci = Campaign.discount_for("product", id)
    ci ? ci.price_for(base) : base
  end

  def on_sale?(variant: nil)
    current_price(variant: variant) < base_price(variant: variant)
  end
```

In `app/models/product_set.rb`, add:

```ruby
  def base_price(variant: nil)
    price
  end

  def current_price(variant: nil)
    ci = Campaign.discount_for("set", id)
    ci ? ci.price_for(price) : price
  end

  def on_sale?(variant: nil)
    current_price < price
  end
```

- [ ] **Step 6: Verify in console**

```bash
bin/rails runner '
p = Product.first
c = Campaign.create!(name: "Test Sale", active: true)
c.campaign_items.create!(kind: "product", item_id: p.id, discount_kind: "percent", percent_off: 20)
puts "base=#{p.base_price} current=#{p.current_price} on_sale=#{p.on_sale?}"
c.destroy
'
```

Expected: `current` is 80% of `base`, `on_sale=true`.

- [ ] **Step 7: Lint & commit**

```bash
bin/rubocop -a app/models/campaign.rb app/models/campaign_item.rb app/models/product.rb app/models/product_set.rb
bin/brakeman -q
git add -A
git commit -m "Add Campaign models and current_price discount layer"
```

---

### Task 10: Show campaign pricing in cards, product page, cart & checkout

**Files:**
- Modify: `app/views/shared/_product_card.html.erb`, `app/views/products/show.html.erb`, `app/models/cart.rb`, `app/views/shared/_cart_contents.html.erb`, `app/controllers/checkout_controller.rb`

- [ ] **Step 1: Add a price helper for struck-through display**

Append to `app/helpers/application_helper.rb` (inside the module):

```ruby
  # Renders the current price, with the original struck through when discounted.
  def price_tag(record, variant: nil)
    cur = record.current_price(variant: variant)
    base = record.base_price(variant: variant)
    if cur < base
      safe_join([
        content_tag(:span, money(cur), class: "price-now"),
        content_tag(:span, money(base), class: "price-was")
      ], " ")
    else
      money(cur)
    end
  end
```

- [ ] **Step 2: Use it on product cards**

In `app/views/shared/_product_card.html.erb`, replace the add button label and the `card-price` div:

Replace:
```erb
      <%= icon :cart %> Add — <%= money record.price %>
```
with:
```erb
      <%= icon :cart %> Add — <%= money record.current_price %>
```

Replace:
```erb
    <div class="card-price"><%= money record.price %></div>
```
with:
```erb
    <div class="card-price"><%= price_tag(record) %></div>
```

- [ ] **Step 3: Use it on the product page**

In `app/views/products/show.html.erb`, replace:
```erb
      <div class="detail-price"><%= money @product.price %></div>
```
with:
```erb
      <div class="detail-price"><%= price_tag(@product) %></div>
```

and in the add-to-cart button label replace `money @product.price` with `money @product.current_price`.

- [ ] **Step 4: Make the cart price from `current_price`**

In `app/models/cart.rb`, replace the `Line` struct definition:

```ruby
  Line = Struct.new(:kind, :id, :qty, :record, keyword_init: true) do
    def subtotal = record.price * qty
  end
```

with:

```ruby
  Line = Struct.new(:kind, :id, :qty, :record, :variant, keyword_init: true) do
    def unit_price = record.current_price(variant: variant)
    def subtotal = unit_price * qty
  end
```

(The `variant` field is nil until Phase 4; `current_price(variant: nil)` already handles that.)

- [ ] **Step 5: Update cart display**

In `app/views/shared/_cart_contents.html.erb`, replace `<%= money l.subtotal %>` (already correct) — no change needed there. To show the per-unit sale, replace the `cart-line-name` block? Not required; subtotal already reflects the discount. Leave as-is.

- [ ] **Step 6: Charge `current_price` at checkout**

In `app/controllers/checkout_controller.rb`, in `create`, change the line-mapping block:

```ruby
      lines = cart.detailed.map do |l|
        total += l.subtotal
        { kind: l.kind, item_id: l.id, name: l.record.name, price: l.record.price, qty: l.qty }
      end
```

to:

```ruby
      lines = cart.detailed.map do |l|
        total += l.subtotal
        { kind: l.kind, item_id: l.id, name: l.record.name, price: l.unit_price, qty: l.qty }
      end
```

- [ ] **Step 7: Add CSS for struck price**

Append to `app/assets/stylesheets/application.css`:

```css
.price-now { color: var(--clay, #9c6f4e); }
.price-was { color: var(--faint); text-decoration: line-through; font-size: 0.85em; margin-left: 4px; }
```

- [ ] **Step 8: Verify**

```bash
bin/rails runner 'c = Campaign.create!(name: "Spring", active: true); c.campaign_items.create!(kind: "product", item_id: Product.first.id, discount_kind: "percent", percent_off: 25)'
bin/rails server
```

The first product shows a struck original + reduced price on its card and detail page. Add it to the cart → subtotal uses the reduced price. Complete checkout → the confirmation/admin order line shows the reduced unit price. Clean up: `bin/rails runner 'Campaign.find_by(slug: "spring").destroy'`.

- [ ] **Step 9: Lint & commit**

```bash
bin/rubocop -a app/models/cart.rb app/controllers/checkout_controller.rb app/helpers/application_helper.rb
git add -A
git commit -m "Apply active campaign pricing across cards, product page, cart and checkout"
```

---

### Task 11: Campaigns admin CRUD

**Files:**
- Create: `app/controllers/admin/campaigns_controller.rb`, `app/views/admin/campaigns/{index,new,edit,_form}.html.erb`
- Modify: `config/routes.rb`, `app/views/admin/shared/_sidebar.html.erb`

- [ ] **Step 1: Route & sidebar**

In `config/routes.rb`, inside `namespace :admin`, after `resources :collections`, add:

```ruby
    resources :campaigns
```

In `app/views/admin/shared/_sidebar.html.erb`, add to the `active` case:

```ruby
           when "campaigns" then "campaigns"
```

and to the `nav` array (after the collections row):

```ruby
    ["campaigns", "Campaigns", :tag, admin_campaigns_path],
```

- [ ] **Step 2: Create the controller**

Create `app/controllers/admin/campaigns_controller.rb`:

```ruby
module Admin
  class CampaignsController < BaseController
    before_action :set_campaign, only: [:edit, :update, :destroy]

    def index
      @campaigns = Campaign.all
    end

    def new
      @campaign = Campaign.new
    end

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

    def edit; end

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

    def destroy
      @campaign.destroy
      redirect_to admin_campaigns_path
    end

    private

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:name, :blurb, :active)
    end

    # params[:items] => { "product-5" => { discount_kind:, sale_price:, percent_off: }, ... }
    # Only rows whose checkbox set a discount_kind are kept.
    def rebuild_items(campaign)
      campaign.campaign_items.destroy_all
      Array(params[:items]).each do |key, attrs|
        next if attrs[:enabled] != "1"
        kind, id = key.split("-", 2)
        dk = attrs[:discount_kind].presence || "fixed"
        campaign.campaign_items.create!(
          kind: kind, item_id: id, discount_kind: dk,
          sale_price: (dk == "fixed" ? attrs[:sale_price] : nil),
          percent_off: (dk == "percent" ? attrs[:percent_off] : nil)
        )
      end
    end

    def attach_banner(campaign)
      campaign.banner.attach(params[:campaign][:banner]) if params.dig(:campaign, :banner).present?
    end
  end
end
```

- [ ] **Step 3: Create the index view**

Create `app/views/admin/campaigns/index.html.erb`:

```erb
<% content_for :title, "Preciso — Campaigns" %>
<div class="pagehead">
  <div>
    <h1 class="display pagehead-title">Campaigns</h1>
    <p class="pagehead-sub">Promotions with reduced prices. Active campaigns show live on the shop.</p>
  </div>
  <div class="pagehead-actions">
    <a href="<%= new_admin_campaign_path %>" class="btn clay sm"><%= icon :plus, size: 16 %> New campaign</a>
  </div>
</div>
<div class="admin-pad">
  <% if @campaigns.empty? %>
    <div class="empty-state">No campaigns yet.</div>
  <% else %>
    <div class="admin-list">
      <% @campaigns.each do |c| %>
        <a href="<%= edit_admin_campaign_path(c) %>" class="admin-row">
          <div class="admin-row-main">
            <div class="admin-row-name"><%= c.name %> <% if c.active %><span class="status-pill" style="background:#e8efe9;color:#5a7060">Active</span><% else %><span class="status-pill" style="background:#efece8;color:#9a9088">Off</span><% end %></div>
            <div class="admin-row-sub"><%= c.campaign_items.count %> items · /campaign/<%= c.slug %></div>
          </div>
          <span class="admin-row-go"><%= icon :arrow, size: 16 %></span>
        </a>
      <% end %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 4: new/edit wrappers**

Create `app/views/admin/campaigns/new.html.erb`:
```erb
<% content_for :title, "Preciso — New campaign" %>
<%= render "form" %>
```
Create `app/views/admin/campaigns/edit.html.erb`:
```erb
<% content_for :title, "Preciso — Edit campaign" %>
<%= render "form" %>
```

- [ ] **Step 5: Create the form partial**

Create `app/views/admin/campaigns/_form.html.erb`:

```erb
<% is_new = @campaign.new_record? %>
<%
  products = Product.includes(:category).order(:id)
  sets = ProductSet.order(:id)
  existing = @campaign.campaign_items.index_by { |ci| "#{ci.kind}-#{ci.item_id}" }
%>
<div class="pagehead">
  <div>
    <h1 class="display pagehead-title"><%= is_new ? "New campaign" : (@campaign.name.presence || "Edit campaign") %></h1>
    <p class="pagehead-sub">Choose items and set each reduced price.</p>
  </div>
  <div class="pagehead-actions">
    <a href="<%= admin_campaigns_path %>" class="btn ghost sm"><%= icon :back, size: 16 %> Back</a>
  </div>
</div>

<%= form_with model: [:admin, @campaign], html: { multipart: true } do |f| %>
  <div class="admin-pad editor-grid" style="align-items:start">
    <div class="card-pad">
      <% if @campaign.errors.any? %><div class="login-err"><%= @campaign.errors.full_messages.to_sentence %></div><% end %>
      <label class="field"><div class="field-label">Name</div>
        <%= f.text_field :name, class: "input", placeholder: "e.g. Summer Glaze" %>
      </label>
      <label class="field"><div class="field-label">Blurb</div>
        <%= f.text_field :blurb, class: "input", placeholder: "One line shown on the banner and campaign page." %>
      </label>
      <label class="field" style="flex-direction:row;align-items:center;gap:10px">
        <%= f.check_box :active %>
        <div class="field-label" style="margin:0">Active (promote on the storefront now)</div>
      </label>

      <div class="field">
        <div class="field-label">Discounted items</div>
        <div class="field-hint">Tick an item, pick a discount type, and enter the value. Products with variations support percentage only.</div>
        <table class="campaign-items">
          <% (products.to_a + sets.to_a).each do |rec| %>
            <% kind = rec.kind %>
            <% key = "#{kind}-#{rec.id}" %>
            <% ci = existing[key] %>
            <tr>
              <td><%= check_box_tag "items[#{key}][enabled]", "1", ci.present? %></td>
              <td><%= rec.name %> <span class="mono" style="color:var(--faint)"><%= kind == "set" ? "set" : rec.category&.name %></span></td>
              <td>
                <% percent_only = kind == "product" && rec.respond_to?(:has_variants?) && rec.has_variants? %>
                <%= select_tag "items[#{key}][discount_kind]",
                      options_for_select(percent_only ? [["% off", "percent"]] : [["Fixed €", "fixed"], ["% off", "percent"]], ci&.discount_kind),
                      class: "input sm" %>
              </td>
              <td><%= number_field_tag "items[#{key}][sale_price]", ci&.sale_price, min: 0, placeholder: "€", class: "input sm", style: "width:90px" %></td>
              <td><%= number_field_tag "items[#{key}][percent_off]", ci&.percent_off, min: 1, max: 99, placeholder: "%", class: "input sm", style: "width:70px" %></td>
            </tr>
          <% end %>
        </table>
      </div>
    </div>

    <div class="stack-18">
      <div class="box" data-controller="imageupload">
        <div class="box-label">Banner image (optional)</div>
        <div class="dropzone" data-imageupload-target="zone" data-action="click->imageupload#browse dragover->imageupload#dragover dragleave->imageupload#dragleave drop->imageupload#drop">
          <% if @campaign.banner.attached? %>
            <%= image_tag @campaign.banner, data: { imageupload_target: "preview" } %>
          <% else %>
            <div data-imageupload-target="placeholder"><%= placeholder(tone: "#efe7dc", name: "Banner", caption: "click or drop photo") %></div>
            <img data-imageupload-target="preview" style="display:none">
          <% end %>
        </div>
        <%= f.file_field :banner, accept: "image/*", style: "display:none", data: { imageupload_target: "input", action: "imageupload#changed" } %>
        <%= hidden_field_tag "campaign[remove_banner]", "0", data: { imageupload_target: "removeFlag" } %>
        <div class="dropzone-actions">
          <button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#browse">Upload</button>
          <% if @campaign.banner.attached? %><button type="button" class="btn ghost sm" style="flex:1" data-action="imageupload#remove">Remove</button><% end %>
        </div>
      </div>
      <div class="box" style="display:flex;flex-direction:column;gap:12px">
        <%= f.submit (is_new ? "Create campaign" : "Save changes"), class: "btn clay" %>
        <% unless is_new %>
          <%= button_to admin_campaign_path(@campaign), method: :delete, class: "danger-btn",
                form: { data: { turbo_confirm: "Delete this campaign?" } } do %>
            <%= icon :trash, size: 16 %> Delete campaign
          <% end %>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

Append CSS to `app/assets/stylesheets/application.css`:

```css
.campaign-items { width: 100%; border-collapse: collapse; margin-top: 10px; }
.campaign-items td { padding: 6px 8px; border-bottom: 1px solid var(--line); vertical-align: middle; font-size: 13px; }
.input.sm { padding: 6px 8px; font-size: 13px; }
```

- [ ] **Step 6: Verify**

Restart the server. `/admin/campaigns` → New → name "Summer Glaze", tick two products, one Fixed €/one % off, set Active, Create. The first product now shows the reduced price on the storefront. Untick an item + save → it returns to full price. Toggle Active off → all prices return to normal.

- [ ] **Step 7: Lint & commit**

```bash
bin/rubocop -a app/controllers/admin/campaigns_controller.rb
bin/brakeman -q
git add -A
git commit -m "Add Campaigns admin CRUD with per-item discounts"
```

---

### Task 12: Campaign banner & landing page

**Files:**
- Create: `app/views/campaigns/show.html.erb`, `app/views/shared/_campaign_banner.html.erb`
- Modify: `config/routes.rb`, `app/controllers/home_controller.rb`, `app/views/home/index.html.erb`, create `app/controllers/campaigns_controller.rb`

- [ ] **Step 1: Route**

In `config/routes.rb` storefront section, add:

```ruby
  get "campaign/:slug", to: "campaigns#show", as: :campaign
```

- [ ] **Step 2: Controller**

Create `app/controllers/campaigns_controller.rb`:

```ruby
class CampaignsController < ApplicationController
  def show
    @campaign = Campaign.active.find_by(slug: params[:slug])
    return render "shared/not_found", status: :not_found unless @campaign

    @records = @campaign.campaign_items.filter_map(&:record)
    track("campaign/#{@campaign.slug}", "Campaign · #{@campaign.name}")
  end
end
```

- [ ] **Step 3: Landing page**

Create `app/views/campaigns/show.html.erb`:

```erb
<% content_for :title, "Preciso — #{@campaign.name}" %>
<main class="wrap fade-up page-top">
  <%= render "shared/breadcrumb", trail: [[@campaign.name, nil]] %>
  <div class="list-head">
    <div>
      <div class="eyebrow clay">Campaign</div>
      <h1 class="display list-title"><%= @campaign.name %></h1>
      <p class="list-blurb"><%= @campaign.blurb %></p>
    </div>
  </div>
  <% if @campaign.banner.attached? %>
    <div class="ratio-box img-frame shop-hero" style="padding-top:32%"><%= image_tag @campaign.banner, alt: @campaign.name, class: "cover-img" %></div>
  <% end %>
  <% if @records.empty? %>
    <div class="empty-state">No items in this campaign.</div>
  <% else %>
    <div class="grid-3 shop-grid">
      <% @records.each do |rec| %>
        <%= render "shared/product_card", record: rec, kind: rec.kind %>
      <% end %>
    </div>
  <% end %>
</main>
```

- [ ] **Step 4: Banner partial**

Create `app/views/shared/_campaign_banner.html.erb`:

```erb
<% banner_campaign = Campaign.active.detect { |c| c.banner.attached? } %>
<% if banner_campaign %>
  <a href="<%= campaign_path(banner_campaign.slug) %>" class="campaign-banner">
    <div class="campaign-banner-frame"><%= image_tag banner_campaign.banner, alt: banner_campaign.name, class: "cover-img" %></div>
    <div class="campaign-banner-text">
      <div class="eyebrow clay">Now on</div>
      <div class="campaign-banner-name"><%= banner_campaign.name %></div>
      <div class="campaign-banner-blurb"><%= banner_campaign.blurb %></div>
      <span class="link-underline">See the campaign <%= icon :arrow, size: 16 %></span>
    </div>
  </a>
<% end %>
```

Append CSS:

```css
.campaign-banner { display: grid; grid-template-columns: 1fr 1fr; gap: 0; border-radius: 16px; overflow: hidden; margin: 0 0 50px; background: var(--paper-2); }
.campaign-banner-frame { position: relative; min-height: 240px; }
.campaign-banner-text { padding: 40px; display: flex; flex-direction: column; justify-content: center; gap: 8px; }
.campaign-banner-name { font-size: 30px; font-family: "Cormorant Garamond", serif; }
.campaign-banner-blurb { color: var(--muted); margin-bottom: 10px; }
@media (max-width: 720px) { .campaign-banner { grid-template-columns: 1fr; } }
```

- [ ] **Step 5: Render the banner on the home page**

In `app/views/home/index.html.erb`, immediately after the hero `</section>` (before the category-tiles section), add:

```erb
  <div class="wrap"><%= render "shared/campaign_banner" %></div>
```

- [ ] **Step 6: Verify**

With an active campaign that has a banner image, the homepage shows the banner; clicking it opens `/campaign/<slug>` listing the discounted items with reduced prices. A non-active campaign slug 404s. An active campaign without a banner shows no homepage banner but its page still works.

- [ ] **Step 7: Lint & commit**

```bash
bin/rubocop -a app/controllers/campaigns_controller.rb
git add -A
git commit -m "Add campaign landing page and homepage banner"
```

---

# Phase 4 — Variations

### Task 13: Attribute models, migration & admin

**Files:**
- Create: migration, `app/models/variant_attribute.rb`, `app/models/variant_attribute_value.rb`, `app/controllers/admin/variant_attributes_controller.rb`, `app/views/admin/variant_attributes/{index,new,edit,_form}.html.erb`
- Modify: `config/routes.rb`, `app/views/admin/shared/_sidebar.html.erb`

- [ ] **Step 1: Generate migration**

```bash
bin/rails g migration CreateVariantAttributes
```

Body:

```ruby
class CreateVariantAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_attributes do |t|
      t.string :name, null: false
      t.integer :position, default: 0
      t.timestamps
    end

    create_table :variant_attribute_values do |t|
      t.references :variant_attribute, null: false, foreign_key: true
      t.string :value, null: false
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
```

```bash
bin/rails db:migrate
```

- [ ] **Step 2: Models**

Create `app/models/variant_attribute.rb`:

```ruby
class VariantAttribute < ApplicationRecord
  has_many :variant_attribute_values, -> { order(:position) }, dependent: :destroy

  default_scope { order(:position) }
  validates :name, presence: true

  accepts_nested_attributes_for :variant_attribute_values
end
```

Create `app/models/variant_attribute_value.rb`:

```ruby
class VariantAttributeValue < ApplicationRecord
  belongs_to :variant_attribute

  default_scope { order(:position) }
  validates :value, presence: true

  def label = "#{variant_attribute.name}: #{value}"
end
```

- [ ] **Step 3: Route & sidebar**

In `config/routes.rb` `namespace :admin`, after `resources :campaigns`, add:

```ruby
    resources :variant_attributes, path: "attributes"
```

In `app/views/admin/shared/_sidebar.html.erb`, add to the `active` case:

```ruby
           when "variant_attributes" then "attributes"
```

and to `nav` (after products, before sets is fine):

```ruby
    ["attributes", "Attributes", :tag, admin_variant_attributes_path],
```

- [ ] **Step 4: Controller (values managed as a repeated text list, like About paragraphs)**

Create `app/controllers/admin/variant_attributes_controller.rb`:

```ruby
module Admin
  class VariantAttributesController < BaseController
    before_action :set_attribute, only: [:edit, :update, :destroy]

    def index
      @attributes = VariantAttribute.all
    end

    def new
      @attribute = VariantAttribute.new
    end

    def create
      @attribute = VariantAttribute.new(name: params.dig(:variant_attribute, :name))
      if @attribute.save
        rebuild_values(@attribute)
        redirect_to admin_variant_attributes_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @attribute.update(name: params.dig(:variant_attribute, :name))
        rebuild_values(@attribute)
        redirect_to admin_variant_attributes_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @attribute.destroy
      redirect_to admin_variant_attributes_path
    end

    private

    def set_attribute
      @attribute = VariantAttribute.find(params[:id])
    end

    # Replace values from the submitted list, preserving existing rows still
    # referenced by variants where the text is unchanged (delete-then-recreate
    # would orphan variant_values, so update in place by index).
    def rebuild_values(attribute)
      submitted = Array(params[:values]).map(&:to_s).map(&:strip).reject(&:empty?)
      existing = attribute.variant_attribute_values.to_a
      submitted.each_with_index do |val, i|
        if (row = existing[i])
          row.update!(value: val, position: i)
        else
          attribute.variant_attribute_values.create!(value: val, position: i)
        end
      end
      existing[submitted.size..]&.each(&:destroy)
    end
  end
end
```

- [ ] **Step 5: Views**

Create `app/views/admin/variant_attributes/index.html.erb`:

```erb
<% content_for :title, "Preciso — Attributes" %>
<div class="pagehead">
  <div>
    <h1 class="display pagehead-title">Attributes</h1>
    <p class="pagehead-sub">Reusable options like Size or Color, used to build product variations.</p>
  </div>
  <div class="pagehead-actions">
    <a href="<%= new_admin_variant_attribute_path %>" class="btn clay sm"><%= icon :plus, size: 16 %> New attribute</a>
  </div>
</div>
<div class="admin-pad">
  <% if @attributes.empty? %>
    <div class="empty-state">No attributes yet.</div>
  <% else %>
    <div class="admin-list">
      <% @attributes.each do |a| %>
        <a href="<%= edit_admin_variant_attribute_path(a) %>" class="admin-row">
          <div class="admin-row-main">
            <div class="admin-row-name"><%= a.name %></div>
            <div class="admin-row-sub"><%= a.variant_attribute_values.map(&:value).join(", ") %></div>
          </div>
          <span class="admin-row-go"><%= icon :arrow, size: 16 %></span>
        </a>
      <% end %>
    </div>
  <% end %>
</div>
```

Create `app/views/admin/variant_attributes/new.html.erb`:
```erb
<% content_for :title, "Preciso — New attribute" %>
<%= render "form" %>
```
Create `app/views/admin/variant_attributes/edit.html.erb`:
```erb
<% content_for :title, "Preciso — Edit attribute" %>
<%= render "form" %>
```

Create `app/views/admin/variant_attributes/_form.html.erb` (reuses the `abouteditor` Stimulus controller's add/remove pattern):

```erb
<% is_new = @attribute.new_record? %>
<div class="pagehead">
  <div>
    <h1 class="display pagehead-title"><%= is_new ? "New attribute" : (@attribute.name.presence || "Edit attribute") %></h1>
    <p class="pagehead-sub">Name the attribute and list its values.</p>
  </div>
  <div class="pagehead-actions">
    <a href="<%= admin_variant_attributes_path %>" class="btn ghost sm"><%= icon :back, size: 16 %> Back</a>
  </div>
</div>

<%= form_with model: [:admin, @attribute], scope: :variant_attribute, data: { controller: "abouteditor", turbo: false } do |f| %>
  <div class="admin-pad" style="max-width:640px">
    <div class="card-pad">
      <% if @attribute.errors.any? %><div class="login-err"><%= @attribute.errors.full_messages.to_sentence %></div><% end %>
      <label class="field"><div class="field-label">Name</div>
        <%= f.text_field :name, class: "input", placeholder: "e.g. Size" %>
      </label>

      <div>
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
          <div class="field-label" style="margin-bottom:0">Values</div>
          <button type="button" class="link-underline" style="font-size:11px" data-action="abouteditor#add"><%= icon :plus, size: 16 %> Add value</button>
        </div>
        <div style="display:flex;flex-direction:column;gap:10px" data-abouteditor-target="list">
          <% @attribute.variant_attribute_values.each do |v| %>
            <div class="para-row">
              <input class="input" name="values[]" value="<%= v.value %>" style="flex:1">
              <button type="button" class="icon-square" data-action="abouteditor#remove"><%= icon :trash, size: 16 %></button>
            </div>
          <% end %>
        </div>
        <template data-abouteditor-target="template">
          <div class="para-row">
            <input class="input" name="values[]" style="flex:1">
            <button type="button" class="icon-square" data-action="abouteditor#remove"><%= icon :trash, size: 16 %></button>
          </div>
        </template>
      </div>

      <div style="display:flex;gap:12px;margin-top:8px">
        <%= f.submit (is_new ? "Create attribute" : "Save changes"), class: "btn clay" %>
        <% unless is_new %>
          <%= button_to admin_variant_attribute_path(@attribute), method: :delete, class: "danger-btn",
                form: { data: { turbo_confirm: "Delete this attribute? Variations using it will lose those values." } } do %>
            <%= icon :trash, size: 16 %> Delete
          <% end %>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

**Note:** confirm the `abouteditor` Stimulus controller's `template`/`list` targets match these names by reading `app/javascript/controllers/abouteditor_controller.js`. If the target names differ, use those names here instead.

- [ ] **Step 6: Verify**

Restart. `/admin/attributes` → New → "Size", add values Small/Medium/Large, Create. Index shows "Small, Medium, Large". Create a second attribute "Color" with Red/Blue/Green. Edit Size, remove "Medium", save → it's gone.

- [ ] **Step 7: Lint & commit**

```bash
bin/rubocop -a app/models/variant_attribute.rb app/models/variant_attribute_value.rb app/controllers/admin/variant_attributes_controller.rb
git add -A
git commit -m "Add global variation attributes admin"
```

---

### Task 14: Variant model & per-product variant admin

**Files:**
- Create: migration, `app/models/variant.rb`, `app/models/variant_value.rb`, `app/controllers/admin/variants_controller.rb`, `app/views/admin/variants/{new,edit,_form}.html.erb`
- Modify: `config/routes.rb`, `app/models/product.rb`, `app/views/admin/products/_form.html.erb`

- [ ] **Step 1: Migration**

```bash
bin/rails g migration CreateVariants
```

Body:

```ruby
class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :price, null: false, default: 0
      t.integer :position, default: 0
      t.timestamps
    end

    create_table :variant_values do |t|
      t.references :variant, null: false, foreign_key: true
      t.references :variant_attribute_value, null: false, foreign_key: true
      t.timestamps
    end
    add_index :variant_values, [:variant_id, :variant_attribute_value_id], unique: true, name: "idx_variant_values_unique"
  end
end
```

```bash
bin/rails db:migrate
```

- [ ] **Step 2: Models**

Create `app/models/variant_value.rb`:

```ruby
class VariantValue < ApplicationRecord
  belongs_to :variant
  belongs_to :variant_attribute_value
end
```

Create `app/models/variant.rb`:

```ruby
class Variant < ApplicationRecord
  belongs_to :product
  has_many_attached :images
  has_many :variant_values, dependent: :destroy
  has_many :variant_attribute_values, through: :variant_values

  default_scope { order(:position) }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  # "Large / Red", ordered by attribute position.
  def label
    variant_attribute_values
      .includes(:variant_attribute)
      .sort_by { |v| v.variant_attribute.position }
      .map(&:value).join(" / ")
  end

  def primary_image
    images.first if images.attached?
  end
end
```

- [ ] **Step 3: Wire Product to variants**

In `app/models/product.rb`, add below the collections associations:

```ruby
  has_many :variants, dependent: :destroy
```

and add these methods (place near `primary_image`):

```ruby
  def has_variants? = variants.exists?

  # Minimum current variant price, for "from €X" display.
  def price_from
    variants.map(&:current_price_via_product).min || current_price
  end
```

Update `primary_image` to fall back to a variant's cover:

```ruby
  def primary_image
    return images.first if images.attached?
    variants.detect(&:primary_image)&.primary_image
  end
```

And add a helper on Variant so `price_from` can apply the campaign discount per variant. In `app/models/variant.rb`, add:

```ruby
  def current_price_via_product
    product.current_price(variant: self)
  end
```

- [ ] **Step 4: Routes (variants nested under products)**

In `config/routes.rb` `namespace :admin`, change `resources :products` to:

```ruby
    resources :products do
      resources :variants, only: [:new, :create, :edit, :update, :destroy]
    end
```

- [ ] **Step 5: Variants controller**

Create `app/controllers/admin/variants_controller.rb`:

```ruby
module Admin
  class VariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: [:edit, :update, :destroy]

    def new
      @variant = @product.variants.new
    end

    def create
      @variant = @product.variants.new(price: params.dig(:variant, :price).to_i)
      if @variant.save
        rebuild_values(@variant)
        attach_images(@variant)
        redirect_to edit_admin_product_path(@product)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @variant.update(price: params.dig(:variant, :price).to_i)
        rebuild_values(@variant)
        purge_images(@variant)
        attach_images(@variant)
        redirect_to edit_admin_product_path(@product)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @variant.destroy
      redirect_to edit_admin_product_path(@product)
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_variant
      @variant = @product.variants.find(params[:id])
    end

    def rebuild_values(variant)
      ids = Array(params[:value_ids]).reject(&:blank?).uniq
      variant.variant_values.destroy_all
      ids.each { |vid| variant.variant_values.create!(variant_attribute_value_id: vid) if VariantAttributeValue.exists?(vid) }
    end

    def attach_images(variant)
      files = Array(params.dig(:variant, :images)).reject(&:blank?)
      variant.images.attach(files) if files.any?
    end

    def purge_images(variant)
      ids = Array(params[:remove_image_ids]).reject(&:blank?)
      variant.images.attachments.where(id: ids).find_each(&:purge) if ids.any?
    end
  end
end
```

- [ ] **Step 6: Variant form partial**

Create `app/views/admin/variants/_form.html.erb`:

```erb
<% is_new = @variant.new_record? %>
<% selected = @variant.variant_attribute_value_ids %>
<div class="pagehead">
  <div>
    <h1 class="display pagehead-title"><%= is_new ? "New variation" : "Edit variation" %></h1>
    <p class="pagehead-sub">for <%= @product.name %></p>
  </div>
  <div class="pagehead-actions">
    <a href="<%= edit_admin_product_path(@product) %>" class="btn ghost sm"><%= icon :back, size: 16 %> Back to piece</a>
  </div>
</div>

<%= form_with url: (is_new ? admin_product_variants_path(@product) : admin_product_variant_path(@product, @variant)),
      method: (is_new ? :post : :patch), scope: :variant, html: { multipart: true } do |f| %>
  <div class="admin-pad editor-grid">
    <div class="card-pad">
      <% VariantAttribute.all.each do |attr| %>
        <div class="field">
          <div class="field-label"><%= attr.name %></div>
          <div class="value-chips">
            <% attr.variant_attribute_values.each do |v| %>
              <label class="chip">
                <%= check_box_tag "value_ids[]", v.id, selected.include?(v.id) %>
                <span><%= v.value %></span>
              </label>
            <% end %>
          </div>
        </div>
      <% end %>
      <% if VariantAttribute.none? %>
        <div class="field-hint">No attributes defined yet. Add some under <a href="<%= admin_variant_attributes_path %>">Attributes</a> first.</div>
      <% end %>
      <label class="field"><div class="field-label">Price (€)</div>
        <%= f.number_field :price, value: @variant.price, min: 0, class: "input" %>
      </label>
    </div>

    <div class="stack-18">
      <div class="box" data-controller="multiupload">
        <div class="box-label">Variation photos</div>
        <% if @variant.images.attached? %>
          <div class="img-grid">
            <% @variant.images.each do |img| %>
              <div class="img-tile" data-multiupload-target="tile">
                <%= image_tag img, class: "cover-img" %>
                <input type="checkbox" name="remove_image_ids[]" value="<%= img.id %>" class="img-remove-cb" data-multiupload-target="removeCb">
                <button type="button" class="img-remove-x" data-action="multiupload#toggleRemove" title="Remove"><%= icon :close, size: 14 %></button>
              </div>
            <% end %>
          </div>
        <% end %>
        <div class="dropzone dz-multi" data-multiupload-target="zone" data-action="click->multiupload#browse dragover->multiupload#dragover dragleave->multiupload#dragleave drop->multiupload#drop">
          <div data-multiupload-target="placeholder"><%= placeholder(tone: @product.tone, name: "Add photos", caption: "click or drop photos") %></div>
          <div class="img-grid previews" data-multiupload-target="previews" style="display:none"></div>
        </div>
        <%= f.file_field :images, multiple: true, accept: "image/*", style: "display:none", data: { multiupload_target: "input", action: "multiupload#changed" } %>
        <div class="dropzone-actions">
          <button type="button" class="btn ghost sm" style="flex:1" data-action="multiupload#browse">Add photos</button>
        </div>
      </div>

      <div class="box" style="display:flex;flex-direction:column;gap:12px">
        <%= f.submit (is_new ? "Add variation" : "Save variation"), class: "btn clay" %>
        <% unless is_new %>
          <%= button_to admin_product_variant_path(@product, @variant), method: :delete, class: "danger-btn",
                form: { data: { turbo_confirm: "Delete this variation?" } } do %>
            <%= icon :trash, size: 16 %> Delete variation
          <% end %>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

Create `app/views/admin/variants/new.html.erb`:
```erb
<% content_for :title, "Preciso — New variation" %>
<%= render "form" %>
```
Create `app/views/admin/variants/edit.html.erb`:
```erb
<% content_for :title, "Preciso — Edit variation" %>
<%= render "form" %>
```

Append CSS:

```css
.value-chips { display: flex; flex-wrap: wrap; gap: 8px; }
.chip { display: inline-flex; align-items: center; gap: 6px; padding: 7px 12px; border: 1px solid var(--line); border-radius: 999px; cursor: pointer; font-size: 13px; }
.chip input { accent-color: var(--clay, #9c6f4e); }
```

- [ ] **Step 7: Add the Variations panel to the product form**

In `app/views/admin/products/_form.html.erb`, inside the right-hand `<div class="stack-18">`, **above** the submit box, add:

```erb
      <div class="box">
        <div class="box-label">Variations</div>
        <% if is_new %>
          <div class="field-hint">Save the piece first, then add variations.</div>
        <% else %>
          <% if @product.variants.any? %>
            <div class="admin-list" style="margin-bottom:12px">
              <% @product.variants.each do |v| %>
                <a href="<%= edit_admin_product_variant_path(@product, v) %>" class="admin-row" style="padding:10px 12px">
                  <div class="admin-row-thumb" style="width:42px;height:42px">
                    <% if v.primary_image %><%= image_tag v.primary_image, class: "cover-img" %><% else %><%= placeholder(tone: @product.tone) %><% end %>
                  </div>
                  <div class="admin-row-main"><div class="admin-row-name"><%= v.label.presence || "Variation ##{v.id}" %></div><div class="admin-row-sub"><%= money v.price %></div></div>
                  <span class="admin-row-go"><%= icon :edit, size: 16 %></span>
                </a>
              <% end %>
            </div>
          <% else %>
            <div class="field-hint" style="margin-bottom:12px">No variations — this piece sells as a single option using the price and photos above.</div>
          <% end %>
          <a href="<%= new_admin_product_variant_path(@product) %>" class="btn ghost sm"><%= icon :plus, size: 16 %> Add variation</a>
        <% end %>
      </div>
```

- [ ] **Step 8: Verify**

Restart. Edit a product → "Save the piece first" hint hidden (it's not new) → click "Add variation". Tick Size: Large + Color: Red, set €120, add photos, Add. Repeat for Small/Red €80 and Small/Blue €80. The product form lists all three with thumbnails and prices. Edit one, change the price, save. Delete one → it disappears.

- [ ] **Step 9: Lint & commit**

```bash
bin/rubocop -a app/models/variant.rb app/models/variant_value.rb app/controllers/admin/variants_controller.rb app/models/product.rb
bin/brakeman -q
git add -A
git commit -m "Add per-product variations admin (attributes, price, photos)"
```

---

### Task 15: Storefront variant switcher & "from" pricing

**Files:**
- Create: `app/javascript/controllers/variants_controller.js`
- Modify: `app/views/products/show.html.erb`, `app/views/shared/_product_card.html.erb`, `app/controllers/products_controller.rb`

- [ ] **Step 1: "from €X" and "View options" on cards for variant products**

In `app/views/shared/_product_card.html.erb`, replace the `card-price` line (after Task 10 it reads `<%= price_tag(record) %>`) with:

```erb
    <div class="card-price">
      <% if kind == "product" && record.has_variants? %>
        from <%= money record.price_from %>
      <% else %>
        <%= price_tag(record) %>
      <% end %>
    </div>
```

For variant products the "Add" button should link to the product page (to pick a variant) instead of adding directly. Replace the whole `button_to … card-add … end` block (the one Task 10 set to `Add — <%= money record.current_price %>`) with:

```erb
    <% if kind == "product" && record.has_variants? %>
      <a href="<%= product_path(record) %>" class="card-add"><%= icon :cart %> View options</a>
    <% else %>
      <%= button_to cart_add_path, params: { kind: kind, id: record.id, name: record.name },
            form: { data: { turbo_stream: true } }, class: "card-add", "aria-label": "Add to cart" do %>
        <%= icon :cart %> Add — <%= money record.current_price %>
      <% end %>
    <% end %>
```

- [ ] **Step 2: Load variants in the controller**

In `app/controllers/products_controller.rb`, in `show`, after `@product = …` guard, add:

```ruby
    @variants = @product.variants.includes(:variant_attribute_values, images_attachments: :blob)
```

- [ ] **Step 3: Variant switcher Stimulus controller**

Create `app/javascript/controllers/variants_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Switches the displayed price, gallery, and add-to-cart variant_id when a
// variant is selected. Variant data is read from data-* on each radio.
export default class extends Controller {
  static targets = ["radio", "price", "variantId", "addLabel", "mainImage", "thumbs"]

  connect() {
    const checked = this.radioTargets.find((r) => r.checked) || this.radioTargets[0]
    if (checked) {
      checked.checked = true
      this.apply(checked)
    }
  }

  select(e) {
    this.apply(e.currentTarget)
  }

  apply(radio) {
    const price = radio.dataset.priceLabel
    this.priceTarget.innerHTML = price
    this.variantIdTarget.value = radio.dataset.variantId
    if (this.hasAddLabelTarget) this.addLabelTarget.textContent = `Add — ${radio.dataset.pricePlain}`
    const images = JSON.parse(radio.dataset.images || "[]")
    if (images.length && this.hasMainImageTarget) {
      this.mainImageTarget.src = images[0]
      if (this.hasThumbsTarget) {
        this.thumbsTarget.innerHTML = images
          .map((src, i) => `<button type="button" class="gallery-thumb ${i === 0 ? "active" : ""}" data-action="gallery#show" data-gallery-target="thumb" data-src="${src}"><img class="cover-img" src="${src}"></button>`)
          .join("")
      }
    }
  }
}
```

- [ ] **Step 4: Render the switcher on the product page**

In `app/views/products/show.html.erb`, wrap the right-hand column so it has the controller, and replace the price + actions region. Change `<div style="padding-top:6px">` to:

```erb
    <div style="padding-top:6px" data-controller="variants">
```

Replace the `detail-price` line with:

```erb
      <div class="detail-price" data-variants-target="price">
        <% if @product.has_variants? %>from <%= money @product.price_from %><% else %><%= price_tag(@product) %><% end %>
      </div>
```

Immediately **after** the `<p class="detail-long">…</p>` line, add the variant selector:

```erb
      <% if @product.has_variants? %>
        <div class="variant-pick">
          <% @variants.each_with_index do |v, i|
               urls = v.images.attached? ? v.images.map { |img| url_for(img) } : (@product.images.attached? ? @product.images.map { |img| url_for(img) } : [])
               cur = v.current_price_via_product
               base = v.price
          %>
            <label class="chip variant-chip">
              <input type="radio" name="variant_choice" <%= "checked" if i.zero? %>
                     data-variants-target="radio" data-action="variants#select"
                     data-variant-id="<%= v.id %>"
                     data-price-plain="<%= money cur %>"
                     data-price-label="<%= j(cur < base ? "<span class='price-now'>#{money cur}</span> <span class='price-was'>#{money base}</span>" : money(cur)) %>"
                     data-images="<%= urls.to_json %>">
              <span><%= v.label %> · <%= money cur %></span>
            </label>
          <% end %>
        </div>
      <% end %>
```

Replace the add-to-cart `button_to` inside `detail-actions` with one that includes the variant id and a live label:

```erb
      <div class="detail-actions">
        <%= form_with url: cart_add_path, data: { turbo_stream: true } do %>
          <input type="hidden" name="kind" value="product">
          <input type="hidden" name="id" value="<%= @product.id %>">
          <input type="hidden" name="name" value="<%= @product.name %>">
          <% if @product.has_variants? %>
            <input type="hidden" name="variant_id" value="<%= @variants.first&.id %>" data-variants-target="variantId">
          <% end %>
          <button type="submit" class="btn clay" style="width:100%;padding:17px 30px">
            <%= icon :cart %> <span data-variants-target="addLabel">Add — <%= money(@product.has_variants? ? @variants.first&.current_price_via_product : @product.current_price) %></span>
          </button>
        <% end %>
      </div>
```

Also add `data-variants-target="mainImage"` to the main gallery `image_tag` and `data-variants-target="thumbs"` to the `gallery-thumbs` container so the switcher can swap photos. In the media block, change:

```erb
            <%= image_tag @product.images.first, alt: @product.name, class: "cover-img", data: { gallery_target: "main" } %>
```
to:
```erb
            <%= image_tag @product.images.first, alt: @product.name, class: "cover-img", data: { gallery_target: "main", variants_target: "mainImage" } %>
```

and add `data-variants-target="thumbs"` to the `<div class="gallery-thumbs">` opening tag.

Append CSS:

```css
.variant-pick { display: flex; flex-wrap: wrap; gap: 8px; margin: 18px 0 8px; }
.variant-chip input { margin-right: 6px; }
.variant-chip:has(input:checked) { border-color: var(--clay, #9c6f4e); background: var(--paper-2); }
```

- [ ] **Step 5: Verify**

Restart. Open a product that has variations. The price shows "from €X"; variant chips list each option with its price. Selecting a chip updates the price, the gallery photos, and the "Add —" label. A product **without** variations behaves exactly as before. A variant product's card shows "from €X" / "View options" and links to the page.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Add storefront variant switcher and from-price display"
```

---

### Task 16: Carry variants through cart, orders & checkout

**Files:**
- Modify: `app/models/cart.rb`, `app/controllers/cart_controller.rb`, `app/views/shared/_cart_contents.html.erb`, `app/controllers/checkout_controller.rb`, `app/models/order_line.rb`, migration for `order_lines`

- [ ] **Step 1: Migration for order line variant snapshot**

```bash
bin/rails g migration AddVariantToOrderLines variant_id:integer variant_label:string
```

Confirm the generated migration body is:

```ruby
class AddVariantToOrderLines < ActiveRecord::Migration[8.1]
  def change
    add_column :order_lines, :variant_id, :integer
    add_column :order_lines, :variant_label, :string
  end
end
```

```bash
bin/rails db:migrate
```

- [ ] **Step 2: Cart matches on variant_id**

In `app/models/cart.rb`, replace the mutation/lookup methods so lines carry `variant_id`:

```ruby
  def add(kind, id, variant_id = nil)
    id = id.to_s
    variant_id = variant_id.presence&.to_s
    line = find(kind, id, variant_id)
    if line
      line["qty"] += 1
    else
      raw << { "kind" => kind, "id" => id, "variant_id" => variant_id, "qty" => 1 }
    end
  end

  def set_qty(kind, id, qty, variant_id = nil)
    line = find(kind, id.to_s, variant_id.presence&.to_s)
    line["qty"] = qty.to_i if line
    raw.reject! { |l| l["qty"].to_i <= 0 }
  end

  def remove(kind, id, variant_id = nil)
    variant_id = variant_id.presence&.to_s
    raw.reject! { |l| l["kind"] == kind && l["id"] == id.to_s && l["variant_id"] == variant_id }
  end
```

Replace `detailed`:

```ruby
  def detailed
    raw.filter_map do |l|
      rec = l["kind"] == "set" ? ProductSet.find_by(id: l["id"]) : Product.find_by(id: l["id"])
      next unless rec
      variant = l["variant_id"].present? ? Variant.find_by(id: l["variant_id"]) : nil
      Line.new(kind: l["kind"], id: l["id"], qty: l["qty"].to_i, record: rec, variant: variant)
    end
  end
```

Replace the private `find`:

```ruby
  def find(kind, id, variant_id = nil) = raw.find { |l| l["kind"] == kind && l["id"] == id && l["variant_id"] == variant_id }
```

(Existing sessions without `variant_id` read as `nil`, matching simple products.)

- [ ] **Step 3: Cart controller passes variant_id**

In `app/controllers/cart_controller.rb`, update the three actions:

```ruby
  def add
    current_cart.add(params[:kind], params[:id], params[:variant_id])
    @toast = "#{params[:name].presence || 'Item'} added"
    respond
  end

  def update
    current_cart.set_qty(params[:kind], params[:id], params[:qty], params[:variant_id])
    respond
  end

  def remove
    current_cart.remove(params[:kind], params[:id], params[:variant_id])
    respond
  end
```

- [ ] **Step 4: Cart line shows the variant label and keeps variant on qty/remove**

In `app/views/shared/_cart_contents.html.erb`:

After the `cart-line-name` div, add the variant label:

```erb
            <% if l.variant %><div class="cart-line-tag"><%= l.variant.label %></div><% end %>
```

Add `variant_id: l.variant&.id` to the params of the remove button and both qty buttons. The remove button becomes:

```erb
            <%= button_to cart_remove_path, method: :delete, params: { kind: l.kind, id: l.id, variant_id: l.variant&.id },
                  form: { data: { turbo_stream: true } }, class: "icon-btn",
                  style: "color:var(--faint)", "aria-label": "Remove" do %><%= icon :close %><% end %>
```

The decrease button params: `{ kind: l.kind, id: l.id, qty: l.qty - 1, variant_id: l.variant&.id }`, and increase: `{ kind: l.kind, id: l.id, qty: l.qty + 1, variant_id: l.variant&.id }`.

- [ ] **Step 5: Checkout snapshots the variant**

In `app/controllers/checkout_controller.rb`, update the line-mapping block to include variant fields:

```ruby
      lines = cart.detailed.map do |l|
        total += l.subtotal
        { kind: l.kind, item_id: l.id, name: l.record.name, price: l.unit_price, qty: l.qty,
          variant_id: l.variant&.id, variant_label: l.variant&.label }
      end
```

- [ ] **Step 6: Show variant label on order lines**

In `app/models/order_line.rb`, add a display helper:

```ruby
  def display_name
    variant_label.present? ? "#{name} — #{variant_label}" : name
  end
```

Then, in the admin order view `app/views/admin/orders/show.html.erb`, wherever the line's `name` is rendered, switch to `line.display_name`. (Read that file and replace the `name` reference on the order-line row.)

- [ ] **Step 7: Verify**

Restart. On a variant product, choose Small/Blue, Add to cart → the drawer shows the name with "Small / Blue" under it and the variant's price. Add Large/Red of the same product → it's a **separate** line, not a quantity bump. Increase/decrease/remove affect only the chosen variant line. Checkout → the order (admin `/admin/orders`) shows each line with "— Large / Red" and the charged price (campaign-discounted if applicable). A simple product still adds/checks out normally.

- [ ] **Step 8: Lint, scan & commit**

```bash
bin/rubocop -a app/models/cart.rb app/controllers/cart_controller.rb app/controllers/checkout_controller.rb app/models/order_line.rb
bin/brakeman -q
git add -A
git commit -m "Carry product variants through cart, checkout and order lines"
```

---

## Final verification

- [ ] **Run the full CI suite locally**

```bash
bin/rubocop
bin/brakeman -q
bin/importmap audit
```

Expected: RuboCop clean, Brakeman no new warnings, importmap audit clean.

- [ ] **End-to-end smoke**

```bash
bin/rails db:reset   # reseed fresh demo state (includes the Oro collection seed)
bin/rails server
```

Walk: home (logo, category images, campaign banner if active) → a category page → a variant product (switcher, from-price) → add two variants → cart (distinct lines, labels, discounted prices) → checkout → confirmation → `/admin` (Attributes, Collections, Campaigns sections; order shows variant labels) → `/about` (image + contacts) → footer contacts/social on every page.

- [ ] **Merge**

```bash
git checkout main
git merge --no-ff catalog-storefront-expansion -m "Catalogue & storefront expansion: variations, collections, campaigns, images, contacts"
```

(Push and deploy with `fly deploy -a preciso` only when the user asks.)
