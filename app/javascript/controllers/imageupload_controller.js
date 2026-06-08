import { Controller } from "@hotwired/stimulus"

// Click/drag-drop photo upload with live preview and a remove flag.
export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "zone", "removeFlag"]

  browse(e) {
    e?.preventDefault()
    this.inputTarget.click()
  }

  changed() {
    const file = this.inputTarget.files[0]
    if (file) this.show(file)
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
    const file = e.dataTransfer.files[0]
    if (!file) return
    this.inputTarget.files = e.dataTransfer.files
    this.show(file)
  }

  show(file) {
    const reader = new FileReader()
    reader.onload = () => {
      this.previewTarget.src = reader.result
      this.previewTarget.style.display = "block"
      if (this.hasPlaceholderTarget) this.placeholderTarget.style.display = "none"
      if (this.hasRemoveFlagTarget) this.removeFlagTarget.value = "0"
    }
    reader.readAsDataURL(file)
  }

  remove(e) {
    e?.preventDefault()
    this.inputTarget.value = ""
    this.previewTarget.removeAttribute("src")
    this.previewTarget.style.display = "none"
    if (this.hasPlaceholderTarget) this.placeholderTarget.style.display = "block"
    if (this.hasRemoveFlagTarget) this.removeFlagTarget.value = "1"
  }
}
