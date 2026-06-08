import { Controller } from "@hotwired/stimulus"

// Live preview of a category's placeholder tone as the color is picked.
export default class extends Controller {
  static targets = ["input", "preview", "value"]

  change() {
    const color = this.inputTarget.value
    const ph = this.previewTarget.querySelector(".ph")
    if (ph) {
      ph.style.background =
        "radial-gradient(120% 90% at 30% 18%, rgba(255,255,255,.85), rgba(255,255,255,0) 55%)," +
        "radial-gradient(120% 120% at 78% 96%, rgba(0,0,0,.05), rgba(0,0,0,0) 60%)," + color
    }
    if (this.hasValueTarget) this.valueTarget.textContent = color
  }
}
