import { Controller } from "@hotwired/stimulus"

// Per-attribute dropdowns choose a variant. The selected value-ids resolve to a
// variant via a server-provided map keyed by the variant's sorted value-ids.
// Unknown combinations hide the price and disable ordering.
export default class extends Controller {
  static targets = ["attrSelect", "price", "variantId", "addLabel", "addButton", "unavailable", "mainImage", "thumbs"]

  connect() {
    this.map = JSON.parse(this.element.dataset.variantsMap || "{}")
    this.apply()
  }

  select() {
    this.apply()
  }

  apply() {
    // Numeric sort to match Ruby's integer Array#sort used to build the map keys.
    const key = this.attrSelectTargets
      .map((s) => parseInt(s.value, 10))
      .sort((a, b) => a - b)
      .join("-")
    const variant = this.map[key]
    if (variant) {
      this.showVariant(variant)
    } else {
      this.showUnavailable()
    }
  }

  showVariant(variant) {
    if (this.hasPriceTarget) {
      this.priceTarget.innerHTML = variant.priceLabel
      this.priceTarget.hidden = false
    }
    if (this.hasUnavailableTarget) this.unavailableTarget.hidden = true
    if (this.hasVariantIdTarget) this.variantIdTarget.value = variant.variantId
    if (this.hasAddLabelTarget) this.addLabelTarget.textContent = `Add — ${variant.pricePlain}`
    if (this.hasAddButtonTarget) this.addButtonTarget.disabled = false

    const images = variant.images || []
    if (images.length && this.hasMainImageTarget) {
      this.mainImageTarget.src = images[0]
      if (this.hasThumbsTarget) {
        this.thumbsTarget.innerHTML = images
          .map((src, i) => `<button type="button" class="gallery-thumb ${i === 0 ? "active" : ""}" data-action="gallery#show" data-gallery-target="thumb" data-src="${src}"><img class="cover-img" src="${src}"></button>`)
          .join("")
      }
    }
  }

  showUnavailable() {
    if (this.hasPriceTarget) this.priceTarget.hidden = true
    if (this.hasUnavailableTarget) this.unavailableTarget.hidden = false
    if (this.hasVariantIdTarget) this.variantIdTarget.value = ""
    if (this.hasAddLabelTarget) this.addLabelTarget.textContent = "Unavailable"
    if (this.hasAddButtonTarget) this.addButtonTarget.disabled = true
  }
}
