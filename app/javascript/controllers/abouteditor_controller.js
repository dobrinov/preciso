import { Controller } from "@hotwired/stimulus"

// Add/remove body paragraph rows on the About editor.
export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    const node = this.templateTarget.content.cloneNode(true)
    this.listTarget.appendChild(node)
  }

  remove(e) {
    e.currentTarget.closest(".para-row")?.remove()
  }
}
