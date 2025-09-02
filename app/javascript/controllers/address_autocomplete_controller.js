import { Controller } from "@hotwired/stimulus"
import MapboxGeocoder from "@mapbox/mapbox-gl-geocoder"

export default class extends Controller {
  static values = { apiKey: String, identifier: String }

  static targets = ["address"]

  connect() {
    this.geocoder = new MapboxGeocoder({
      enableGeolocation: this.addressTarget.dataset.enableGeolocation === "true",
      placeholder: this.addressTarget.placeholder || "Search",
      accessToken: this.apiKeyValue,
      types: "place, locality, neighborhood, address, poi",
      language: 'fr',
      proximity: {
        longitude: 2.3522,
        latitude: 48.8566
      }
    })

    this.geocoder.addTo(this.element)
    this.geocoder.on("result", event => {
      this.#setInputValue(event)
      this.dispatch("inputFilled", { detail: this.identifierValue })
    })
    this.geocoder.on("clear", () => this.#clearInputValue())

    this.geocoder.on("results", (e) => {
      if (!e.features) return

      const scored = e.features.sort((a, b) => {
        const aScore = this.#scoreFeature(a)
        const bScore = this.#scoreFeature(b)
        return bScore - aScore
      })

      e.features = scored
    })

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

  #scoreFeature(feature) {
    let score = 0
    const name = feature.place_name.toLowerCase()

    if (name.includes("france")) score += 50
    if (feature.context?.some(c => c.text_fr === "France")) score += 50
    if (feature.place_type.includes("address")) score += 10
    if (feature.place_type.includes("locality")) score += 5

    return score
  }

  _userLocation() {
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
