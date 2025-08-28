import { Controller } from "@hotwired/stimulus"
import MapboxGeocoder from "@mapbox/mapbox-gl-geocoder"

// Connects to data-controller="address-autocomplete"
export default class extends Controller {
  static values = { apiKey: String }

  static targets = ["address"]
  connect() {
    this.geocoder = new MapboxGeocoder({
      enableGeolocation: this.addressTarget.dataset.enableGeolocation === "true",
      placeholder: this.addressTarget.placeholder || "Search",
      accessToken: this.apiKeyValue,
      types: "country,region,place,locality,neighborhood,address",
      language: 'fr'
    })

    this.geocoder.addTo(this.element)
    this.geocoder.on("result", event => this.#setInputValue(event))
    this.geocoder.on("clear", () => this.#clearInputValue())


    this.element.querySelector("button.mapboxgl-ctrl-geocoder--button[aria-label=Geolocate]")?.setAttribute("type", "button")
  }

  disconnect() {
    this.geocoder.onRemove()
  }

  #setInputValue(event) {
    this.addressTarget.value = event.result["place_name"]
  }

  #clearInputValue() {
    this.addressTarget.value = ""
  }
}
