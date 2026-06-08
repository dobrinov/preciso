import { Controller } from "@hotwired/stimulus"

// The set builder: pick pieces, adjust quantities, price the set,
// and see the saving vs. buying separately. Mirrors the prototype.
export default class extends Controller {
  static targets = ["picker", "chosen", "hidden", "sepTotal", "sepRow", "count", "empty", "price", "hint", "name", "submit"]
  static values = { items: Array, products: Array }

  connect() {
    this.items = [...this.itemsValue].map(String)
    this.byId = {}
    this.productsValue.forEach((p) => { this.byId[String(p.id)] = p })
    this.render()
  }

  add(e) {
    this.items.push(String(e.currentTarget.dataset.id))
    this.render()
  }

  inc(e) {
    this.items.push(String(e.currentTarget.dataset.id))
    this.render()
  }

  dec(e) {
    const id = String(e.currentTarget.dataset.id)
    const idx = this.items.indexOf(id)
    if (idx >= 0) this.items.splice(idx, 1)
    this.render()
  }

  money(n) { return "€" + Math.round(n) }

  grouped() {
    const order = []
    const counts = {}
    this.items.forEach((id) => {
      if (counts[id] === undefined) { counts[id] = 0; order.push(id) }
      counts[id]++
    })
    return order.map((id) => ({ id, qty: counts[id], p: this.byId[id] })).filter((g) => g.p)
  }

  render() {
    const groups = this.grouped()

    // chosen rows
    this.chosenTarget.innerHTML = groups.map((g) => `
      <div class="chosen-row">
        <div class="thumb" style="background:${g.p.tone}"></div>
        <div style="flex:1;min-width:0">
          <div class="cname">${this.escape(g.p.name)}</div>
          <div class="cprice">${this.money(g.p.price)} each</div>
        </div>
        <div class="qty-mini">
          <button type="button" data-id="${g.id}" data-action="setbuilder#dec">${MINUS}</button>
          <span class="num">${g.qty}</span>
          <button type="button" data-id="${g.id}" data-action="setbuilder#inc">${PLUS}</button>
        </div>
      </div>`).join("")

    // hidden inputs (one per occurrence)
    this.hiddenTarget.innerHTML = this.items
      .map((id) => `<input type="hidden" name="set[item_ids][]" value="${id}">`).join("")

    // separate total
    const sep = groups.reduce((n, g) => n + g.p.price * g.qty, 0)
    this.sepTotalTarget.textContent = this.money(sep)
    this.sepRowTarget.style.display = groups.length ? "flex" : "none"
    this.emptyTarget.style.display = groups.length ? "none" : "block"
    this.countTarget.textContent = this.items.length

    // picker badges
    this.pickerTargets.forEach((btn) => {
      const id = String(btn.dataset.id)
      const n = this.items.filter((x) => x === id).length
      const badge = btn.querySelector(".count")
      btn.classList.toggle("in-set", n > 0)
      if (badge) { badge.textContent = n; badge.style.display = n > 0 ? "grid" : "none" }
    })

    this.renderHint(sep)
    this.validate()
  }

  renderHint(sep) {
    const price = parseFloat(this.priceTarget.value)
    if (sep > 0 && !isNaN(price)) {
      this.hintTarget.textContent = price < sep
        ? `Saves ${this.money(sep - price)} vs. separate.`
        : "Priced at or above separate total."
    } else {
      this.hintTarget.textContent = "Often a little under the separate total."
    }
  }

  validate() {
    const ok = this.nameTarget.value.trim() && this.priceTarget.value !== "" && this.items.length > 0
    if (this.hasSubmitTarget) this.submitTarget.disabled = !ok
    // re-render hint on price/name input
    this.renderHint(this.grouped().reduce((n, g) => n + g.p.price * g.qty, 0))
  }

  escape(s) {
    const d = document.createElement("div")
    d.textContent = s
    return d.innerHTML
  }
}

const MINUS = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M5 12h14"/></svg>`
const PLUS = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M12 5v14M5 12h14"/></svg>`
