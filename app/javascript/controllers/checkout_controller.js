import { Controller } from "@hotwired/stimulus"

// Checkout form:
// - enables the submit button only when name, email, phone and — when delivery
//   options exist — a country, a delivery option and its destination fields
//   (street address, or city + courier office) are filled in;
// - shows the chosen option's price and updates the total;
// - switches between "pay online" and "pay later" copy: online only when card
//   payments are on AND a priced delivery option is chosen;
// - when vacation mode is on (the modal target is present), confirms slower
//   processing before the order is submitted.
// Hidden groups have their inputs disabled so they are never submitted.
export default class extends Controller {
  static targets = ["name", "email", "phone", "country", "countryOther", "otherField",
                    "optionGroup", "addressFields", "delivery", "total", "submit", "form", "modal"]
  static values = { subtotal: Number, online: Boolean, currency: String }

  connect() { this.validate() }

  // Show only the chosen country's delivery options; preselect a lone option.
  chooseCountry() {
    const choice = this.countryTarget.value
    this.optionGroupTargets.forEach(group => {
      const show = group.dataset.country === choice
      group.hidden = !show
      const radios = group.querySelectorAll("input[type=radio]")
      radios.forEach(r => { r.disabled = !show; if (!show) r.checked = false })
      if (show && radios.length === 1) radios[0].checked = true
    })
    this.validate()
  }

  validate() {
    const emailOk = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(this.emailTarget.value)
    let valid = this.nameTarget.value.trim() && emailOk && this.phoneTarget.value.trim().length >= 6

    let cost = null
    if (this.hasCountryTarget) {
      const choice = this.countryTarget.value
      const other = choice === "other"
      const picked = this.element.querySelector("input[name=delivery_option_id]:checked:not(:disabled)")
      const kind = picked ? picked.dataset.kind : (other ? "address" : null)
      if (picked) cost = Number(picked.dataset.cost)

      this.otherFieldTarget.hidden = !other
      this.addressFieldsTargets.forEach(group => {
        const show = group.dataset.kind === kind
        group.hidden = !show
        group.querySelectorAll("input").forEach(i => { i.disabled = !show })
        if (show && [...group.querySelectorAll("input")].some(i => !i.value.trim())) valid = false
      })

      if (!choice) valid = false
      if (other && !this.countryOtherTarget.value.trim()) valid = false
      if (choice && !other && !picked) valid = false

      this.deliveryTarget.textContent =
        cost !== null ? this.money(cost)
          : other ? "Quoted by email"
          : choice ? "Choose an option" : "Choose country"
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
