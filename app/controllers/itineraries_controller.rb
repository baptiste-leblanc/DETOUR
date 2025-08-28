class ItinerariesController < ApplicationController
  require 'json'

  def best_itinerary
    itinerary_objective = ItineraryObjective.find(params["itinerary_objective_id"])
    @itinerary = itinerary_objective.itineraries.first
    authorize(@itinerary)
  end

  def alternative_itinerary

  end

  # def show
  #   @itinerary = Itinerary.find(params[:id])
  #   authorize(@itinerary)
  # end

  private

  def sort_waypoints(departure, arrival, pois)

    api_key = ENV['MAPBOX_API_KEY']
    url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/ POINT DE DEPART"
    # Each
    url.add(lat, long)
  # end
  url.add(long lat de arrivée)
    url.add(du rest)
    url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/2.3469%2C48.8609%3B2.3522%2C48.8719%3B2.350867%2C48.866582%3B2.370867%2C48.876582?access_token=#{api_key}&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    sorted_waypoints = data["waypoints"].sort_by { |waypoint| waypoint["waypoint_index"] }

    puts sorted_waypoints
  end
end
