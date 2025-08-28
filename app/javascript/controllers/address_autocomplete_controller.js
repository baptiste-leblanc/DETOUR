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
      types: "place,locality,neighborhood,address,poi",
      proximity: this._userLocation(),
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

  _userLocation() {
    // récupère la position navigateur
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((pos) => {
        this.geocoder.setProximity({
          longitude: 2.333333,
          latitude: 48.866667
        })
      })
    }
    return undefined
  }
}
