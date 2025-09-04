import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    apiKey: String,
    waypoints: { type: Array, default: [] },
    currentItineraryIndex: Number,
    isHome: { type: Boolean, default: false }
  }

  connect() {
    if (this.map) return;

    if (!this.apiKeyValue) {
      console.error("Missing Mapbox API key!");
      return;
    }

    this.initializeMap();
  }

  initializeMap() {
    mapboxgl.accessToken = this.apiKeyValue;

    this.map = new mapboxgl.Map({
      container: "map",
      style: "mapbox://styles/gaelroussel/cmf0u6wzg00cm01sbgwopdjnd/draft",
      center: [2.3522, 48.8566],
      zoom: 12
    });

    this.geolocate = new mapboxgl.GeolocateControl({
      positionOptions: { enableHighAccuracy: true },
      trackUserLocation: true,
      showUserHeading: true
    });

    this.map.addControl(this.geolocate);

    this.map.on("load", () => {
      if (this.isHomeValue) {
        this.geolocate.trigger();
        this.map.setZoom(12);
      } else {
        this.geolocate.trigger();
      }
      this.renderRoute();
    });
  }

  disconnect() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

  currentItineraryIndexValueChanged() {
    if (this.map && this.map.isStyleLoaded()) {
      this.renderRoute();
    } else {
      this.map?.once("load", () => this.renderRoute());
    }
  }

  async renderRoute() {
    const itinerary = this.waypointsValue[this.currentItineraryIndexValue];
    if (!itinerary || itinerary.length === 0) return;

    try {
      const routeData = await this.fetchRouteData(itinerary);
      this.updateDurationAndDistance(routeData.duration, routeData.distance);
      this.cleanupPreviousRoute();
      this.addRouteToMap(routeData.geometry);
      this.addMarkersToMap(itinerary);
      this.fitMapBounds(routeData.geometry);
    } catch (error) {
      console.error('Error rendering route:', error);
    }
  }

  async fetchRouteData(itinerary) {
    const coordinates = itinerary.map(waypoint => waypoint.location.join(',')).join(';');
    const url = `https://api.mapbox.com/directions/v5/mapbox/walking/${coordinates}?geometries=geojson&overview=full&access_token=${this.apiKeyValue}`;

    const response = await fetch(url);
    const data = await response.json();

    if (!data.routes || data.routes.length === 0) {
      throw new Error('No routes found in response');
    }

    const route = data.routes[0];
    return {
      geometry: route.geometry,
      duration: route.duration,
      distance: route.distance
    };
  }

  updateDurationAndDistance(duration, distance) {
    const minutes = Math.round(duration / 60);
    const kilometers = Math.round(distance / 1000);

    // Update single duration element (for initial load)
    const singleDurationElement = document.querySelector('.duration');
    if (singleDurationElement) {
      singleDurationElement.textContent = `${minutes} min`;
    }

    const singleDistanceElement = document.querySelector('.distance');
    if (singleDistanceElement) {
      singleDistanceElement.textContent = `${kilometers}km`;
    }

    // Update specific itinerary duration/distance elements
    const durationElements = document.querySelectorAll('.duration');
    const distanceElements = document.querySelectorAll('.distance');

    if (durationElements[this.currentItineraryIndexValue]) {
      durationElements[this.currentItineraryIndexValue].textContent = `${minutes} min`;
    }

    if (distanceElements[this.currentItineraryIndexValue]) {
      distanceElements[this.currentItineraryIndexValue].textContent = `${kilometers} km`;
    }
  }

  cleanupPreviousRoute() {
    // Remove previous route layer and source
    if (this.map.getLayer("route")) this.map.removeLayer("route");
    if (this.map.getSource("route")) this.map.removeSource("route");

    // Remove previous markers
    if (this.markers) {
      this.markers.forEach(marker => marker.remove());
    }
  }

  addRouteToMap(geometry) {
    this.map.addSource("route", {
      type: "geojson",
      data: { type: "Feature", geometry }
    });

    this.map.addLayer({
      id: "route",
      type: "line",
      source: "route",
      layout: { "line-join": "round", "line-cap": "round" },
      paint: { "line-color": "#161273", "line-width": 3 }
    });
  }

  addMarkersToMap(waypoints) {
    this.markers = waypoints.map(waypoint => {
      const marker = new mapboxgl.Marker({ color: '#161273' })
        .setLngLat(waypoint.location)
        .addTo(this.map);

      if (waypoint.description || waypoint.name) {
        const popup = this.createPopup(waypoint);
        marker.setPopup(popup);
      }

      return marker;
    });
  }

  getCategoryEmoji(category) {
    const categoryEmojis = {
      'Historical Sites': '🏛️',
      'Culture & Arts': '🎭',
      'Museums & Exhibitions': '🖼️',
      'Religious': '⛪',
      'Cafés & Bistros': '☕',
      'Restaurants': '🍽️',
      'Desserts & Pastry Shops': '🧁',
      'Food Markets & Street Food': '🥘',
      'Shopping & Leisure': '🛍️',
      'Nature & Parks': '🌳',
      'Knowledge & Institutions': '📚'
    };

    return categoryEmojis[category] || '📍';
  }
  
  createPopup(waypoint) {
    const categoryEmoji = this.getCategoryEmoji(waypoint.category);

    return new mapboxgl.Popup({
      className: 'glass-popup me-2',
      offset: 25,
      closeOnClick: true,
      closeButton: true
    }).setHTML(`
      <div class="m-2" style="background:transparent">
        <h5 style="margin: 0 0 10px 0;">${categoryEmoji} ${waypoint.name}</h5>
        <p style="margin: 0;font-size:16px;margin-left:5px;">${waypoint.description || ''}</p>
      </div>
    `);
  }


  fitMapBounds(geometry) {
    const bottomSheet = document.querySelector(".liquid-glass")

    const bounds = new mapboxgl.LngLatBounds();
    geometry.coordinates.forEach(coordinate => bounds.extend(coordinate));
    this.map.fitBounds(bounds, { padding: { top:50, right: 50, left: 50, bottom: bottomSheet.clientHeight + 20 } });
  }
}
