import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
export default class extends Controller {
  static targets = ["map"]

  connect() {
    // Listen for bootstrap carousel slide event
    this.element.addEventListener("slid.bs.carousel", this.updateItineraryIndex)
  }

  disconnect() {
    this.element.removeEventListener("slid.bs.carousel", this.updateItineraryIndex)
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
}
