import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["hideable", "show"]

  call(event) {
    event.preventDefault()

    const isHidden = this.hideableTarget.classList.contains("opacity-0") &&
                     this.hideableTarget.classList.contains("z-n1");

    if (isHidden) {
      // Show sidebar
      this.hideableTarget.classList.remove("d-none")
      this.hideableTarget.classList.remove("z-n1")
      this.hideableTarget.classList.remove("opacity-0")
      this.hideableTarget.classList.add("z-3")
      this.showTarget.classList.add("opacity-100")

      // Add nav-visible class to body for hamburger animation
      document.body.classList.add("nav-visible")
    } else {
      // Hide sidebar
      this.hideableTarget.classList.add("d-none")
      this.hideableTarget.classList.add("opacity-0")
      this.hideableTarget.classList.add("z-n1")
      this.hideableTarget.classList.remove("z-3")
      this.showTarget.classList.remove("opacity-100")

      // Remove nav-visible class from body for hamburger animation
      document.body.classList.remove("nav-visible")
    }
  }
}
