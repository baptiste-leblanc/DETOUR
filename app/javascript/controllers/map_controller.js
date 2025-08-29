import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

export default class extends Controller {
  static values = { apiKey: String, waypoints: Array }

  connect() {
    this.map = new mapboxgl.Map({
      accessToken: this.apiKeyValue,
      container: "map",
      style: "mapbox://styles/mapbox/streets-v11",
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

      console.log(this.waypointsValue)
      const url = `https://api.mapbox.com/directions/v5/mapbox/walking/${this.waypointsValue.map(c => c.location.join(',')).join(';')}?geometries=geojson&overview=full&access_token=${this.apiKeyValue}`;
      console.log(url)

      fetch(url)
        .then(res => res.json())
        .then(data => {
          const route = data.routes[0].geometry;

          const duration = data.routes[0].duration;
          const minutes = Math.round(duration / 60);
          document.querySelector('#duration').textContent = `${minutes} min`
          
          const distance_m = data.routes[0].distance;
          const distance_km = Math.round(distance_m / 1000);
          document.querySelector('#distance').textContent = `${distance_km}km`

          this.map.addSource("route", {
            type: "geojson",
            data: { type: "Feature", geometry: route }
          });
          this.map.addLayer({
            id: "route",
            type: "line",
            source: "route",
            layout: { "line-join": "round", "line-cap": "round" },
            paint: { "line-color": "#3B82F6", "line-width": 5 }
          });
          this.waypointsValue.forEach(coord => {
            new mapboxgl.Marker().setLngLat(coord).addTo(this.map);
            console.log(coord);
          });
          const bounds = new mapboxgl.LngLatBounds();
          route.coordinates.forEach(c => bounds.extend(c));
          this.map.fitBounds(bounds, { padding: 50 });
        });
    });
  }
}
