import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-visibility"
export default class extends Controller {
  static targets = ["departureAddress", "arrivalAddress", "detourCtas"]

  toggleVisibility(event) {
    if (event.detail === "departureField") {
      this.arrivalAddressTarget.classList.remove("d-none")
    } else if (event.detail === "arrivalField") {
      this.detourCtasTarget.classList.remove("d-none")
    }
  }
}
