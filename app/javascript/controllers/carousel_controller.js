import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
export default class extends Controller {
  static targets = ["map"]

  connect() {
    // Listen for bootstrap carousel slide event
    this.element.addEventListener("slid.bs.carousel", this.updateItineraryIndex)
    // Initialiser Bootstrap Carousel avec les bonnes options
    this.initializeCarousel()
  }

  disconnect() {
    this.element.removeEventListener("slid.bs.carousel", this.updateItineraryIndex)
  }

  initializeCarousel() {
    // S'assurer que Bootstrap Carousel est configuré correctement
    if (window.bootstrap && window.bootstrap.Carousel) {
      this.bsCarousel = new window.bootstrap.Carousel(this.element, {
        interval: false,
        ride: false,
        touch: true,
        wrap: true
      })
    }
  }

  updateItineraryIndex = (event) => {
    // Get the index of the active slide
    const index = event.to; // Bootstrap provides "to" index

    // Find the map element (the Stimulus map controller)
    const mapElement = document.querySelector("[data-controller~='map']")
    if (!mapElement) return

    // Update Stimulus value on the map controller
    mapElement.setAttribute("data-map-current-itinerary-index-value", index)

    // ✅ Stimulus will trigger `currentItineraryIndexValueChanged` automatically
  }

  // Méthodes publiques pour contrôler le carousel programmatiquement
  next() {
    if (this.bsCarousel) {
      this.bsCarousel.next()
    }
  }

  prev() {
    if (this.bsCarousel) {
      this.bsCarousel.prev()
    }
  }

  goToSlide(index) {
    if (this.bsCarousel) {
      this.bsCarousel.to(index)
    }
  }
}
