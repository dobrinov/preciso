import { Controller } from "@hotwired/stimulus"

// Multi-photo upload: preview newly selected files and mark existing ones for removal.
export default class extends Controller {
  static targets = ["input", "zone", "placeholder", "previews"]

  browse(e) {
    e?.preventDefault()
    this.inputTarget.click()
  }

  changed() {
    this.renderPreviews(this.inputTarget.files)
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
    this.inputTarget.files = e.dataTransfer.files
    this.renderPreviews(e.dataTransfer.files)
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
