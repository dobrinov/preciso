import { Controller } from "@hotwired/stimulus"

// Switches the displayed price, gallery, and add-to-cart variant_id when a
// variant is selected. Variant data is read from data-* on each radio.
export default class extends Controller {
  static targets = ["radio", "price", "variantId", "addLabel", "mainImage", "thumbs"]

  connect() {
    const checked = this.radioTargets.find((r) => r.checked) || this.radioTargets[0]
    if (checked) {
      checked.checked = true
      this.apply(checked)
    }
  }

  select(e) {
    this.apply(e.currentTarget)
  }

  apply(radio) {
    const price = radio.dataset.priceLabel
    this.priceTarget.innerHTML = price
    this.variantIdTarget.value = radio.dataset.variantId
    if (this.hasAddLabelTarget) this.addLabelTarget.textContent = `Add — ${radio.dataset.pricePlain}`
    const images = JSON.parse(radio.dataset.images || "[]")
    if (images.length && this.hasMainImageTarget) {
      this.mainImageTarget.src = images[0]
      if (this.hasThumbsTarget) {
        this.thumbsTarget.innerHTML = images
          .map((src, i) => `<button type="button" class="gallery-thumb ${i === 0 ? "active" : ""}" data-action="gallery#show" data-gallery-target="thumb" data-src="${src}"><img class="cover-img" src="${src}"></button>`)
          .join("")
      }
    }
  }
}
