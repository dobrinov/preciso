import { Controller } from "@hotwired/stimulus"

// Multi-photo upload: accumulate newly selected files across clicks/drops,
// preview them, and mark existing attachments for removal.
export default class extends Controller {
  static targets = ["input", "zone", "placeholder", "previews"]

  connect() {
    this.buffer = new DataTransfer()
  }

  browse(e) {
    e?.preventDefault()
    this.inputTarget.click()
  }

  changed() {
    this.absorb(this.inputTarget.files)
  }

  dragover(e) {
    e.preventDefault()
    this.zoneTarget.classList.add("drag")
  }

  dragleave() {
    this.zoneTarget.classList.remove("drag")
  }

  drop(e) {
    e.preventDefault()
    this.zoneTarget.classList.remove("drag")
    if (!e.dataTransfer.files.length) return
    this.absorb(e.dataTransfer.files)
  }

  // Append the given files to the buffer, then write the buffer back to the
  // real input so all of them submit with the form.
  absorb(files) {
    Array.from(files).forEach((f) => this.buffer.items.add(f))
    this.inputTarget.files = this.buffer.files
    this.renderPreviews(this.buffer.files)
  }

  renderPreviews(files) {
    this.previewsTarget.innerHTML = ""
    if (!files || !files.length) {
      this.previewsTarget.style.display = "none"
      this.placeholderTarget.style.display = "block"
      return
    }
    this.placeholderTarget.style.display = "none"
    this.previewsTarget.style.display = "grid"
    Array.from(files).forEach((file) => {
      const reader = new FileReader()
      const tile = document.createElement("div")
      tile.className = "img-tile"
      reader.onload = () => {
        tile.innerHTML = `<img class="cover-img" src="${reader.result}">`
      }
      reader.readAsDataURL(file)
      this.previewsTarget.appendChild(tile)
    })
  }

  toggleRemove(e) {
    const tile = e.currentTarget.closest(".img-tile")
    const cb = tile.querySelector(".img-remove-cb")
    cb.checked = !cb.checked
    tile.classList.toggle("marked", cb.checked)
  }
}
