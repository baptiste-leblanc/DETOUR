class ItinerariesController < ApplicationController
  require 'json'
  def show
    @itineraries = Itinerary.all
  end

  private

  def sort_waypoints(departure, arrival, pois)

    departure.longitude
    api_key = ENV['MAPBOX_API_KEY']
    base_url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/"

    # Each
    pois = PointOfInterest.all

    coordinates = []
    coordinates << "#{addr_wagon.longitude},#{addr_wagon.latitude};"

    pois.each do |point|
      coordinates << "#{point.address.longitude},#{point.address.latitude};"
    end

    coordinates << "#{addr_toureiffel.longitude},#{addr_toureiffel.latitude}"

    coordinates << "?access_token=#{api_key}&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    string_coord = coordinates.join("")
    url = "#{base_url}#{string_coord}"
    # url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/2.3469%2C48.8609%3B2.3522%2C48.8719%3B2.350867%2C48.866582%3B2.370867%2C48.876582?access_token=#{api_key}&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    sorted_waypoints = data["waypoints"].sort_by { |waypoint| waypoint["waypoint_index"] }

    p sorted_waypoints
  end
end


# https://api.mapbox.com/optimized-trips/v1/mapbox/walking/2.379982,48.864892;2.342542,48.860393;2.36041,48.85552;2.305082,48.856271?access_token=pk.eyJ1IjoiYmFwdGkiLCJhIjoiY21kd3dnNWN6MWM2dTJtcXk1emM2YjRlYSJ9.Yl4EyIRYufUcEQVudpKhoQ&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last
