# Vacation mode — checkout confirmation for slower processing

## Goal

Let the owner flag a period of slower order processing ("I am on vacation") with a
custom message. While it's on, clicking **Place order** at checkout shows a
confirmation modal with that message, asking the customer whether to proceed.

## Storage — `Vacation` singleton

New model `Vacation` (singleton, mirroring `About`/`HomePage`):

```ruby
class Vacation < ApplicationRecord
  def self.instance
    first || create!(
      active: false,
      message: "Orders placed now may take a little longer than usual to prepare. Thank you for your patience — Bianna will be in touch to confirm timing."
    )
  end
end
```

Migration: `create_table :vacations` with `active` (boolean, null: false, default:
false) and `message` (text).

A memoized helper in `ApplicationHelper`:

```ruby
def vacation
  @_vacation ||= Vacation.instance
end
```

## Admin

- Route: `resource :vacation, only: [ :edit, :update ], controller: "vacation"` (in
  the `:admin` namespace).
- `Admin::VacationController` (`edit` loads `Vacation.instance`; `update` reads
  top-level params — `params[:active]` (checkbox "1"/"0") and `params[:message]` —
  and saves, redirecting with a `notice`), mirroring `Admin::AboutController`.
- `app/views/admin/vacations/edit.html.erb`: header ("Vacation"), a flash notice, an
  **Active** checkbox ("Slower processing — show a notice before checkout"), and a
  **message** textarea, styled like the About editor.
- Sidebar nav (`admin/shared/_sidebar.html.erb`): add
  `["vacation", "Vacation", :doc, edit_admin_vacation_path]` and
  `when "vacation" then "vacation"` to the active case.

## Checkout confirmation modal

In `app/views/checkout/new.html.erb`:

- Give the form a target + submit guard:
  `form_with url: checkout_path, method: :post, data: { turbo: false, checkout_target: "form", action: "submit->checkout#guard" }`.
- When `vacation.active?`, render a hidden modal as the last child of the `checkout`
  controller element:
  ```erb
  <% if vacation.active? %>
    <div class="vac-modal" data-checkout-target="modal" hidden>
      <div class="vac-scrim" data-action="click->checkout#cancelOrder"></div>
      <div class="vac-panel">
        <div class="vac-title">Before you order</div>
        <p class="vac-message"><%= vacation.message %></p>
        <div class="vac-actions">
          <button type="button" class="btn ghost" data-action="checkout#cancelOrder">Go back</button>
          <button type="button" class="btn clay" data-action="checkout#confirmOrder">Place order anyway</button>
        </div>
      </div>
    </div>
  <% end %>
  ```
  `vacation.message` is escaped via `<%= %>` (no HTML injection).

Extend `app/javascript/controllers/checkout_controller.js` (targets add `form`,
`modal`):

```ruby
guard(e) {
  if (this.hasModalTarget && !this.confirmed) { e.preventDefault(); this.modalTarget.hidden = false }
}
confirmOrder() { this.confirmed = true; this.modalTarget.hidden = true; this.formTarget.requestSubmit() }
cancelOrder() { if (this.hasModalTarget) this.modalTarget.hidden = true }
```

Flow: with vacation off there is no `modal` target, so `guard` is a no-op and checkout
submits as today. With it on, the first submit is intercepted and the modal opens;
"Place order anyway" sets `confirmed`, closes the modal, and `requestSubmit()`s — the
re-fired submit passes the guard (confirmed) and posts. "Go back" just closes it. The
existing validity-gated submit button is unchanged.

This is an informational, client-side confirmation — not a server-enforced gate
(a JS-disabled client would submit directly), which suits a courtesy notice.

## CSS

A small block in `application.css`: `.vac-modal` (fixed, full-screen, grid place-items
center, z-index above the header; `[hidden]` hides it), `.vac-scrim` (absolute
backdrop, dark translucent), `.vac-panel` (white card, max-width ~420px, padding),
`.vac-title`/`.vac-message`/`.vac-actions` (flex, gap), consistent with the existing
design tokens.

## Files

- Migration: `create_table :vacations`.
- New: `app/models/vacation.rb`, `app/controllers/admin/vacation_controller.rb`,
  `app/views/admin/vacations/edit.html.erb`.
- Modify: `config/routes.rb`, `app/helpers/application_helper.rb`,
  `app/views/admin/shared/_sidebar.html.erb`, `app/views/checkout/new.html.erb`,
  `app/javascript/controllers/checkout_controller.js`, `app/assets/stylesheets/application.css`.

## Out of scope

- Storefront / checkout banner (per the chosen scope — modal only).
- Automatic date-range scheduling (manual on/off toggle; a future enhancement).
- Server-side enforcement / recording acknowledgement on the order.

## Verification

No automated suite. `bin/rubocop` + a test-env `ActionDispatch::Integration::Session`
and rendered-HTML checks:

1. Vacation off → checkout page has no `vac-modal`; `guard` no-ops; an order posts
   normally and is created.
2. Vacation on → checkout page renders the `vac-modal` (hidden) with the message;
   the form carries the `checkout#guard` submit action.
3. `Admin::VacationController#update` toggles `active` and saves `message`
   (admin-authenticated PATCH); the checkout page reflects it.
4. Posting an order still works server-side when vacation is on (the modal is
   client-side; `POST /checkout` creates the order regardless).
