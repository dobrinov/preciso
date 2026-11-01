import { Controller } from "@hotwired/stimulus"

// Analytics beacon: one ping when the page shows (proves a real browser ran
// it) and one when it is left, carrying the time spent on the page.
export default class extends Controller {
  static values = { token: String }

  connect() {
    if (!this.tokenValue || document.documentElement.hasAttribute("data-turbo-preview")) return
    this.start = Date.now()
    this.send({})
    this.onHide = () => this.leave()
    this.onVisibility = () => { if (document.visibilityState === "hidden") this.leave() }
    window.addEventListener("pagehide", this.onHide)
    document.addEventListener("visibilitychange", this.onVisibility)
  }

  disconnect() {
    this.leave()
    window.removeEventListener("pagehide", this.onHide)
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  leave() {
    if (!this.start || this.left) return
    this.left = true
    this.send({ d: Date.now() - this.start })
  }

  send(extra) {
    const body = new FormData()
    body.append("t", this.tokenValue)
    Object.entries(extra).forEach(([k, v]) => body.append(k, v))
    if (navigator.sendBeacon) navigator.sendBeacon("/a/pv", body)
    else fetch("/a/pv", { method: "POST", body, keepalive: true })
  }
}
