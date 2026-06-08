import { Controller } from "@hotwired/stimulus"

// Header scroll border, mobile menu, and cart drawer open/close.
export default class extends Controller {
  static targets = ["header", "mobNav"]

  connect() {
    this.onScroll = this.onScroll.bind(this)
    this.onKey = this.onKey.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("keydown", this.onKey)
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("keydown", this.onKey)
  }

  onScroll() {
    if (!this.hasHeaderTarget) return
    this.headerTarget.classList.toggle("scrolled", window.scrollY > 10)
  }

  onKey(e) {
    if (e.key === "Escape") this.closeCart()
  }

  toggleMenu() {
    if (this.hasMobNavTarget) this.mobNavTarget.classList.toggle("open")
  }

  openCart() {
    document.body.classList.add("cart-open")
  }

  closeCart() {
    document.body.classList.remove("cart-open")
  }
}
