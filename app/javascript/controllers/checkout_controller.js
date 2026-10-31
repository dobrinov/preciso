import { Controller } from "@hotwired/stimulus"

// Checkout form:
// - enables the submit button only when name, email, phone (and, when delivery
//   countries exist, a country) look valid;
// - shows the delivery price for the chosen country and updates the total;
// - switches between the "pay online" and "pay later" copy: online only when
//   card payments are on AND the country has a fixed delivery price;
// - when vacation mode is on (the modal target is present), confirms slower
//   processing before the order is submitted.
export default class extends Controller {
  static targets = ["name", "email", "phone", "country", "countryOther", "otherField",
                    "addressFields", "address",
                    "delivery", "total", "submit", "form", "modal"]
  static values = { subtotal: Number, online: Boolean, currency: String }

  connect() { this.validate() }

  validate() {
    const emailOk = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(this.emailTarget.value)
    let valid = this.nameTarget.value.trim() && emailOk && this.phoneTarget.value.trim().length >= 6

    let cost = null // delivery price of the chosen country, if it has one
    if (this.hasCountryTarget) {
      const choice = this.countryTarget.value
      const other = choice === "other"
      this.otherFieldTarget.hidden = !other
      if (choice && !other) cost = Number(this.countryTarget.selectedOptions[0].dataset.cost)
      if (!choice) valid = false
      if (other && !this.countryOtherTarget.value.trim()) valid = false
      // Any chosen country means delivery, so the address is required.
      this.addressFieldsTarget.hidden = !choice
      if (choice && this.addressTargets.some(i => !i.value.trim())) valid = false

      this.deliveryTarget.textContent =
        cost !== null ? this.money(cost) : other ? "Quoted by email" : "Choose country"
      this.totalTarget.textContent = this.money(this.subtotalValue + (cost || 0))
    }

    this.mode(this.onlineValue && cost !== null ? "online" : "offline")
    this.submitTarget.disabled = !valid
  }

  mode(name) {
    this.element.querySelectorAll("[data-show]").forEach(el => { el.hidden = el.dataset.show !== name })
  }

  money(n) { return `${this.currencyValue}${n}` }

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
