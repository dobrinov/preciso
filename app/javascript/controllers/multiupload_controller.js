import { Controller } from "@hotwired/stimulus"

// Multi-photo upload + drag-to-reorder. Existing image tiles (server-rendered,
// with data-image-id) and newly added preview tiles share one grid. Dragging
// reorders them; the resulting order — existing attachment ids and "new"
// placeholders, minus any marked for removal — is written to a hidden field that
// the controller resolves on save. The first tile is the cover.
export default class extends Controller {
  static targets = ["input", "zone", "grid", "order"]

  connect() {
    this.buffer = new DataTransfer()
    this.syncOrder()
  }

  // ---- add files ----
  browse(e) {
    e?.preventDefault()
    this.inputTarget.click()
  }

  changed() {
    this.absorb(this.inputTarget.files)
  }

  zoneDragover(e) {
    e.preventDefault()
    this.zoneTarget.classList.add("drag")
  }

  zoneDragleave() {
    this.zoneTarget.classList.remove("drag")
  }

  zoneDrop(e) {
    e.preventDefault()
    this.zoneTarget.classList.remove("drag")
    if (e.dataTransfer.files.length) this.absorb(e.dataTransfer.files)
  }

  absorb(files) {
    Array.from(files).forEach((f) => this.buffer.items.add(f))
    this.inputTarget.files = this.buffer.files
    this.renderNewTiles()
  }

  renderNewTiles() {
    this.gridTarget.querySelectorAll(".img-tile-new").forEach((t) => t.remove())
    Array.from(this.buffer.files).forEach((file) => {
      const tile = document.createElement("div")
      tile.className = "img-tile img-tile-new"
      tile.draggable = true
      tile.dataset.new = "true"
      tile.dataset.action = "dragstart->multiupload#tileDragstart dragover->multiupload#tileDragover drop->multiupload#tileDrop dragend->multiupload#tileDragend"
      const img = document.createElement("img")
      img.className = "cover-img"
      const reader = new FileReader()
      reader.onload = () => { img.src = reader.result }
      reader.readAsDataURL(file)
      tile.appendChild(img)
      this.gridTarget.appendChild(tile)
    })
    this.syncOrder()
  }

  // ---- mark existing for removal ----
  toggleRemove(e) {
    const tile = e.currentTarget.closest(".img-tile")
    const cb = tile.querySelector(".img-remove-cb")
    if (cb) {
      cb.checked = !cb.checked
      tile.classList.toggle("marked", cb.checked)
    }
    this.syncOrder()
  }

  // ---- drag reorder ----
  tileDragstart(e) {
    this.dragged = e.currentTarget
    e.dataTransfer.effectAllowed = "move"
  }

  tileDragover(e) {
    e.preventDefault()
    const target = e.currentTarget
    if (!this.dragged || target === this.dragged) return
    const rect = target.getBoundingClientRect()
    const after = e.clientX - rect.left > rect.width / 2
    this.gridTarget.insertBefore(this.dragged, after ? target.nextSibling : target)
  }

  tileDrop(e) {
    e.preventDefault()
  }

  tileDragend() {
    this.dragged = null
    this.syncOrder()
  }

  // ---- write the order tokens ----
  syncOrder() {
    if (!this.hasOrderTarget) return
    const tiles = Array.from(this.gridTarget.querySelectorAll(".img-tile"))
    const tokens = tiles
      .filter((t) => !t.classList.contains("marked"))
      .map((t) => t.dataset.imageId || "new")
    this.orderTarget.value = tokens.join(",")
    const firstKept = tiles.find((t) => !t.classList.contains("marked"))
    tiles.forEach((t) => t.classList.toggle("is-cover", t === firstKept))
  }
}
