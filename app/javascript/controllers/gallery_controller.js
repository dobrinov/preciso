import { Controller } from "@hotwired/stimulus"

// Product image gallery: click a thumbnail to swap the main image.
export default class extends Controller {
  static targets = ["main", "thumb"]

  show(e) {
    const src = e.currentTarget.dataset.src
    if (this.hasMainTarget) this.mainTarget.src = src
    this.thumbTargets.forEach((t) => t.classList.toggle("active", t === e.currentTarget))
  }
}
