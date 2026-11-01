import { Controller } from "@hotwired/stimulus"

// Re-submits a GET filter form when one of its selects changes.
export default class extends Controller {
  submit() { this.element.requestSubmit() }
}
