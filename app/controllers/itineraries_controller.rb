class ItinerariesController < ApplicationController
  require 'json'

  def best_itinerary
    @itinerary_objective = ItineraryObjective.find(params["itinerary_objective_id"])
    @itinerary = @itinerary_objective.itineraries.first
    @waypoints = sort_waypoints(@itinerary_objective.departure_address, @itinerary_objective.arrival_address, @itinerary.point_of_interests)
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

    departure.longitude
    api_key = ENV['MAPBOX_API_KEY']
    base_url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/"

    # Each

    coordinates = []
    coordinates << "#{departure.longitude},#{departure.latitude};"

    pois.each do |point|
      coordinates << "#{point.address.longitude},#{point.address.latitude};"
    end

    coordinates << "#{arrival.longitude},#{arrival.latitude}"

    coordinates << "?access_token=#{api_key}&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    string_coord = coordinates.join("")
    url = "#{base_url}#{string_coord}"
    # url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/2.3469%2C48.8609%3B2.3522%2C48.8719%3B2.350867%2C48.866582%3B2.370867%2C48.876582?access_token=#{api_key}&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    sorted_waypoints = data["waypoints"].sort_by { |waypoint| waypoint["waypoint_index"] }

    p sorted_waypoints
  end

  def set_duration

  end
end
