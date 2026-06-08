import { Controller } from "@hotwired/stimulus"

// Auto-dismiss toasts appended (via Turbo Stream) into the host.
export default class extends Controller {
  static targets = ["item"]

  itemTargetConnected(el) {
    setTimeout(() => {
      el.style.transition = "opacity .3s, transform .3s"
      el.style.opacity = "0"
      el.style.transform = "translateY(8px)"
      setTimeout(() => el.remove(), 300)
    }, 2600)
  }
}
