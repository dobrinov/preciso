import { Controller } from "@hotwired/stimulus"

// Submits its form as soon as it appears (used to hand off to the payment page).
// The visible button stays as a fallback if this doesn't run.
export default class extends Controller {
  connect() { this.element.submit() }
}
