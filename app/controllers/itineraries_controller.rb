class ItinerariesController < ApplicationController
  require 'json'

  def best_itinerary
    @itinerary_objective = ItineraryObjective.find(params["itinerary_objective_id"])
    @itinerary = @itinerary_objective.itineraries.first

    waypoints_data = sort_waypoints(@itinerary_objective.departure_address, @itinerary_objective.arrival_address, @itinerary.point_of_interests)
    @waypoints = [waypoints_data[:waypoints]]
    @sorted_pois = waypoints_data[:sorted_pois]

    @duration = direct_duration(@itinerary_objective.departure_address, @itinerary_objective.arrival_address)
    authorize(@itinerary)
  end

  def direct_itinerary
    @itinerary_objective = ItineraryObjective.find(params["itinerary_objective_id"])
    @itinerary = @itinerary_objective.itineraries.first
    authorize(@itinerary)
  end

  def alternative_itinerary
    @itinerary_objective = ItineraryObjective.find(params["itinerary_objective_id"])
    @itineraries = @itinerary_objective.itineraries[1..-1]
    @itineraries_data = @itineraries.map do |itinerary|
    waypoints_data = sort_waypoints(@itinerary_objective.departure_address, @itinerary_objective.arrival_address, itinerary.point_of_interests)
    {
      itinerary: itinerary,
      waypoints: waypoints_data[:waypoints],
      sorted_pois: waypoints_data[:sorted_pois]
    }

    end

  # Pour la compatibilité avec la carte
  @waypoints = @itineraries_data.map { |data| data[:waypoints] }

  authorize(@itineraries.first)
  end

  def show
    @itinerary = Itinerary.find(params[:id])
    @itinerary_objective = ItineraryObjective.find(params["itinerary_objective_id"])

    waypoints_data = sort_waypoints(@itinerary_objective.departure_address, @itinerary_objective.arrival_address, @itinerary.point_of_interests)
    @waypoints = [waypoints_data[:waypoints]]
    @sorted_pois = waypoints_data[:sorted_pois]

    authorize(@itinerary)
  end

  private

  def sort_waypoints(departure, arrival, pois)
    api_key = ENV['MAPBOX_API_KEY']
    base_url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/"

    coordinates = []
    coordinates << "#{departure.longitude},#{departure.latitude};"

    pois.each do |point|
      coordinates << "#{point.address.longitude},#{point.address.latitude};"
    end

    coordinates << "#{arrival.longitude},#{arrival.latitude}"
    coordinates << "?access_token=#{api_key}&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"

    string_coord = coordinates.join
    url = "#{base_url}#{string_coord}"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    sorted_waypoints = data["waypoints"].sort_by { |waypoint| waypoint["waypoint_index"] }

    sorted_pois = []

    sorted_waypoints[0]["name"] = ""

    pois.each_with_index do |poi, index|
      waypoint_index = index + 1
      if waypoint_index < sorted_waypoints.length - 1
        sorted_waypoints[waypoint_index]["name"] = poi.name
        sorted_waypoints[waypoint_index]["description"] = poi.description
        sorted_waypoints[waypoint_index]["category"] = poi.category if poi.respond_to?(:category)

        original_waypoint_index = sorted_waypoints[waypoint_index]["waypoint_index"]
        if original_waypoint_index > 0 && original_waypoint_index <= pois.length
          sorted_pois << pois[original_waypoint_index - 1]
        end
      end
    end

    sorted_waypoints[-1]["name"] = ""

    {
      waypoints: sorted_waypoints,
      sorted_pois: sorted_pois
    }
  end

  def direct_duration(departure, arrival)
    api_key = ENV['MAPBOX_API_KEY']
    base_url = "https://api.mapbox.com/directions/v5/mapbox/walking/"

    coords = "#{departure.longitude},#{departure.latitude};#{arrival.longitude},#{arrival.latitude}"
    end_url = "?alternatives=false&continue_straight=true&geometries=geojson&overview=full&steps=false&access_token=#{api_key}"
    full_url = "#{base_url}#{coords}#{end_url}"

    response = Net::HTTP.get(URI(full_url))
    data = JSON.parse(response)

    duration_seconds = data["routes"][0]["duration"]
    duration_minutes = (duration_seconds / 60.0).round
  end
end
