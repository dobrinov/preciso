import { Controller } from "@hotwired/stimulus"

// Enable the place-order button only when name, email and phone look valid.
export default class extends Controller {
  static targets = ["name", "email", "phone", "submit"]

  connect() { this.validate() }

  validate() {
    const emailOk = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(this.emailTarget.value)
    const valid = this.nameTarget.value.trim() && emailOk && this.phoneTarget.value.trim().length >= 6
    this.submitTarget.disabled = !valid
  }
}
