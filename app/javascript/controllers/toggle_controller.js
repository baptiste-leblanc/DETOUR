import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["hideable", "show"]
  call() {
    event.preventDefault()
    if (this.hideableTarget.classList.contains("opacity-0") && this.hideableTarget.classList.contains("z-n1")) {
      this.hideableTarget.classList.remove("z-n1")
      this.hideableTarget.classList.remove("opacity-0")
      this.hideableTarget.classList.add("z-3")
      this.showTarget.classList.add("opacity-100")
    } else {
      this.hideableTarget.classList.add("opacity-0")
      this.hideableTarget.classList.add("z-n1")
      this.hideableTarget.classList.remove("z-3")
      this.showTarget.classList.remove("opacity-100")
    }
  }
}
