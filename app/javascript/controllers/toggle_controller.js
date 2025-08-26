import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["hideable", "show"]
  call() {
    event.preventDefault()
    if (this.hideableTarget.classList.contains("opacity-0")) {
      this.hideableTarget.classList.remove("opacity-0")
      this.showTarget.classList.add("opacity-100")
    } else {
      this.hideableTarget.classList.add("opacity-0")
      this.showTarget.classList.remove("opacity-100")
    }
  }
}
