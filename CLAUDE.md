# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Preciso is a single-studio porcelain storefront + admin panel: **Rails 8.1 / Ruby 4.0, SQLite, Hotwire (Turbo + Stimulus) over importmap, Propshaft, Active Storage on local disk**. There is no CSS framework — the entire design system is one hand-written stylesheet at `app/assets/stylesheets/application.css`. No JS build step (importmap), no on-the-fly image variants (so no libvips/imagemagick needed to run locally).

## Commands

```bash
bin/setup            # install deps, prepare DB (seed catalogue + demo data), starts server
bin/rails db:setup   # create, migrate, and seed only
bin/rails db:reset   # wipe and re-seed to a fresh demo state
bin/dev              # run the server (thin wrapper over `bin/rails server`)
bin/rails server     # http://localhost:3000 — admin at /admin (password: studio)

bin/ci               # full CI suite (setup + rubocop + security scans)
bin/rubocop          # lint (rubocop-rails-omakase); -a to autocorrect
bin/brakeman         # security static analysis
bin/bundler-audit    # gem CVE audit
bin/importmap audit  # JS dependency audit
```

There is **no automated test suite** (no `test/` directory). CI runs RuboCop + the three security scanners only — do not claim tests pass; there are none to run.

## Architecture

### Two surfaces, one codebase
- **Storefront** controllers inherit `ApplicationController`. **Admin** controllers (`app/controllers/admin/`) inherit `Admin::BaseController`, which forces `layout "admin"` and `require_admin`.
- **Admin auth is a single hardcoded password** (`"studio"`) in `Admin::SessionsController::PASSWORD`, gated only by a `session[:admin]` boolean. There is no user model. (Note: a blank password also authenticates — see `sessions_controller.rb`.)

### Products and Sets are duck-typed, not a shared base class
`Product` and `ProductSet` are independent models that both expose `kind` (`"product"` / `"set"`), `tone`, and `price`, so views, cart, and orders treat them polymorphically. A `ProductSet` bundles products via `SetItem` (`has_many :products, through: :set_items`) and computes `separate_total` (price if bought individually) vs. its own `price`. Anywhere an item is referenced by `(kind, id)` — cart lines, order lines — that pair is how you resolve back to the right model.

### The cart is session-backed, not persisted
`Cart` (`app/models/cart.rb`) is a plain wrapper over `session[:cart]`, an array of `{"kind","id","qty"}` hashes — it is **not** an ActiveRecord model. Access it via `current_cart` (helper in `ApplicationController`). `#detailed` resolves each line to its live `Product`/`ProductSet` at render time, so deleted catalogue items silently drop out. Cart mutations respond with Turbo Streams (`app/views/cart/*.turbo_stream.erb`).

### Checkout has no payment
`CheckoutController#create` builds an `Order` + `OrderLine`s (price snapshotted per line), clears the cart, and redirects to a confirmation page keyed by order number. Order numbers come from `Order.next_number` (`"PR-" + (1043 + count)`); `Order#to_param` is the number, so routes use `param: :number`. Status flow is `new → preparing → fulfilled → cancelled` (see `Order::STATUSES`).

### Analytics is a custom, on-device-style event log
`Event` records storefront activity. `ApplicationController#track(page_key, label, ...)` writes `pageview` events tagged with a per-browser `session[:sid]`; `add_cart` and `order` events are written from the cart/checkout controllers. **Admin views are never tracked** — `track` is only invoked from storefront controllers, never `Admin::BaseController`. The dashboard/analytics screens are built entirely from `Event` class methods (`summary`, `top_pages`, `top_pieces`, `daily`, `recent`). Tracking failures are rescued and logged, never raised.

### Category slugs are intentionally sticky
`Category#assign_slug` generates a slug from the name on create, but only regenerates it when the **name changes** — so existing shop URLs (`/shop/:slug`) stay stable across unrelated edits. `default_scope` orders categories by `position`.

### Singletons & storage
- `About` is a singleton row fetched via `About.instance`; its `body` is a JSON-serialized array of paragraph strings.
- Product photos: `has_many_attached :images` (first attachment = cover via `primary_image`). Sets: `has_one_attached :image`. Images render as-is, no variants.

## Deployment (Fly.io)

App name `preciso`, region `fra`, SQLite on a Fly volume mounted at `/mnt/preciso` (`config/database.yml` production `DATABASE_PATH` default). Served by **Thruster** in front of Puma: Thruster binds `HTTP_PORT` (set to `8080` in `fly.toml` to match `internal_port`) and proxies to Puma on `3000`. The Docker entrypoint runs `bin/rails db:prepare` before the server starts, so cold boots are slow — keep the VM at 1 GB and avoid scale-to-zero if cold-start 502s matter. Deploy with `fly deploy -a preciso`.
