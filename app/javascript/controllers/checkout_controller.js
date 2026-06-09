import { Controller } from "@hotwired/stimulus"

// Enable the place-order button only when name, email and phone look valid, and —
// when vacation mode is on (the modal target is present) — confirm slower
// processing before the order is submitted.
export default class extends Controller {
  static targets = ["name", "email", "phone", "submit", "form", "modal"]

  connect() { this.validate() }

  validate() {
    const emailOk = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(this.emailTarget.value)
    const valid = this.nameTarget.value.trim() && emailOk && this.phoneTarget.value.trim().length >= 6
    this.submitTarget.disabled = !valid
  }

  // Intercept the first submit while vacation mode is on and open the modal.
  guard(e) {
    if (this.hasModalTarget && !this.confirmed) {
      e.preventDefault()
      this.modalTarget.hidden = false
    }
  }

  confirmOrder() {
    this.confirmed = true
    if (this.hasModalTarget) this.modalTarget.hidden = true
    this.formTarget.requestSubmit()
  }

  cancelOrder() {
    if (this.hasModalTarget) this.modalTarget.hidden = true
  }
}
