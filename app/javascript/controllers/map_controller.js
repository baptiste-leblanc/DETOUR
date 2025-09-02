import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    apiKey: String,
    waypoints: { type: Array, default: [] },
    currentItineraryIndex: Number
  }

  connect() {
    if (this.map) return;

    if (!this.apiKeyValue) {
      console.error("Missing Mapbox API key!");
      return;
    }

    mapboxgl.accessToken = this.apiKeyValue;

    this.map = new mapboxgl.Map({
      container: "map",
      style: "mapbox://styles/gaelroussel/cmf0u6wzg00cm01sbgwopdjnd/draft",
      center: [2.3522, 48.8566],
      zoom: 12
    });

    const geolocate = new mapboxgl.GeolocateControl({
      positionOptions: { enableHighAccuracy: true },
      trackUserLocation: true,
      showUserHeading: true
    });

    this.map.addControl(geolocate);

    this.map.on("load", () => {
      geolocate.trigger();
      this.renderRoute(); // initial render
    });
  }

  disconnect() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

  // Stimulus callback: triggered whenever currentItineraryIndexValue changes
  currentItineraryIndexValueChanged() {
    if (this.map && this.map.isStyleLoaded()) {
      this.renderRoute();
    } else {
      this.map?.once("load", () => this.renderRoute());
    }
  }

  renderRoute() {
    const itinerary = this.waypointsValue[this.currentItineraryIndexValue];
    if (!itinerary || itinerary.length === 0) return;

    const url = `https://api.mapbox.com/directions/v5/mapbox/walking/${itinerary.map(c => c.location.join(',')).join(';')}?geometries=geojson&overview=full&access_token=${this.apiKeyValue}`;

    fetch(url)
      .then(res => res.json())
      .then(data => {
        if (!data.routes || data.routes.length === 0) {
          console.error('No routes found in response:', data);
          return;
        }

        const route = data.routes[0].geometry;
        const duration = data.routes[0].duration;
        const minutes = Math.round(duration / 60);

        const durationElement = document.querySelectorAll('.duration')[this.currentItineraryIndexValue];
        if (durationElement) durationElement.textContent = `${minutes} min`;

        const distance_m = data.routes[0].distance;
        const distance_km = Math.round(distance_m / 1000);

        const distanceElement = document.querySelectorAll('.distance')[this.currentItineraryIndexValue];
        if (distanceElement) distanceElement.textContent = `${distance_km}km`;

        // --- Clean up previous route & markers ---
        if (this.map.getLayer("route")) this.map.removeLayer("route");
        if (this.map.getSource("route")) this.map.removeSource("route");
        if (this.markers) this.markers.forEach(m => m.remove());

        // --- Add new route ---
        this.map.addSource("route", {
          type: "geojson",
          data: { type: "Feature", geometry: route }
        });
        this.map.addLayer({
          id: "route",
          type: "line",
          source: "route",
          layout: { "line-join": "round", "line-cap": "round" },
          paint: { "line-color": "#161273", "line-width": 3 }
        });

        // --- Add markers ---
        this.markers = itinerary.map(waypoint =>
          new mapboxgl.Marker({ color: '#161273' })
            .setLngLat(waypoint.location)
            .addTo(this.map)
        );

        // --- Fit bounds ---
        const bounds = new mapboxgl.LngLatBounds();
        route.coordinates.forEach(c => bounds.extend(c));
        this.map.fitBounds(bounds, { padding: 120 });
      })
      .catch(error => {
        console.error('Error fetching route:', error);
      });
  }
}
