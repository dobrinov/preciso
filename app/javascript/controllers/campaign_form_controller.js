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
    if (this.hasAllTarget) this.allTarget.style.display = all ? "" : "none"
    if (this.hasSelectionTarget) this.selectionTarget.style.display = all ? "none" : ""
  }

  syncRow(select) {
    const row = select.closest("tr")
    if (!row) return
    const percent = select.value === "percent"
    const fixed = row.querySelector(".js-fixed")
    const pct = row.querySelector(".js-percent")
    if (fixed) fixed.style.display = percent ? "none" : ""
    if (pct) pct.style.display = percent ? "" : "none"
  }
}
