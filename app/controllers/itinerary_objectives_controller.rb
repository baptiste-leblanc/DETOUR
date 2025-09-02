class ItineraryObjectivesController < ApplicationController
  require "json"
  require "uri"
  require 'net/http'
  require 'concurrent-ruby'

def create
  @itinerary_objective = ItineraryObjective.new(itinerary_objective_params)
  @itinerary_objective.user = current_user
  authorize(@itinerary_objective)

  count = 0
  if @itinerary_objective.save
    area_for_POIs = corridor_polygon(@itinerary_objective.departure_address.latitude, @itinerary_objective.departure_address.longitude, @itinerary_objective.arrival_address.latitude, @itinerary_objective.arrival_address.longitude)
    pois_area_coords = area_for_POIs[:geometry][:coordinates].first

    pois_in_db = Address.where(address_type: "poi").in_bounding_box(pois_area_coords)

    if pois_in_db.count > 20
      # situation 1: on a déjà plus de 20 POIs dans la zone donc on va juste les classifier
      filtered_pois_collection = classify_pois(pois_in_db)
      filtered_pois_collection.each do |poi_collection|
        itinerary = Itinerary.create(theme: poi_collection["theme_name"], description: poi_collection["theme_description"], itinerary_objective_id: @itinerary_objective.id)
        poi_collection["points_of_interest"].each do |poi|
          point_of_interest = PointOfInterest.find_by_name(poi)
          ItineraryPointOfInterest.create(point_of_interest: point_of_interest, itinerary: itinerary)
        end
      end
    else
      # situation 2: on en a moins donc on va en générer
      filtered_pois_collection = generate_POIs(area_for_POIs, pois_in_db)
      filtered_pois_collection.each do |poi_collection|
        itinerary = Itinerary.create(theme: poi_collection["theme_name"], description: poi_collection["theme_description"], itinerary_objective_id: @itinerary_objective.id)
        poi_collection["poi_names"].each do |poi|
          point_of_interest = PointOfInterest.find_by_name(poi)
          ItineraryPointOfInterest.create(point_of_interest: point_of_interest, itinerary: itinerary)
        end
      end
    end

    redirect_to best_itinerary_itinerary_objective_itineraries_path(@itinerary_objective)
  else
    redirect_to itinerary_objective_path
  end
end


  private

  def itinerary_objective_params
    params.require(:itinerary_objective).permit(
      departure_address_attributes: [:id, :full_address],
      arrival_address_attributes: [:id, :full_address]
    )
  end

  # START: Code permettant de générer une zone de points d'intérêts

  # Conversion degrés ↔ radians
  def deg2rad(deg)
    deg * Math::PI / 180
  end

  def rad2deg(rad)
    rad * 180 / Math::PI
  end

  # Bearing (azimut) entre deux points
  def bearing(lat1, lon1, lat2, lon2)
    d_lon = deg2rad(lon2 - lon1)
    lat1 = deg2rad(lat1)
    lat2 = deg2rad(lat2)

    y = Math.sin(d_lon) * Math.cos(lat2)
    x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(d_lon)
    (rad2deg(Math.atan2(y, x)) + 360) % 360
  end

  # Déplacement d’un point (lat, lon) sur une distance (m) et un azimut (°)
  def destination_point(lat, lon, distance_m, bearing_deg)
    r = 6_371_000.0 # rayon de la Terre en mètres
    δ = distance_m / r
    θ = deg2rad(bearing_deg)

    lat1 = deg2rad(lat)
    lon1 = deg2rad(lon)

    lat2 = Math.asin(Math.sin(lat1) * Math.cos(δ) + Math.cos(lat1) * Math.sin(δ) * Math.cos(θ))
    lon2 = lon1 + Math.atan2(Math.sin(θ) * Math.sin(δ) * Math.cos(lat1),
                            Math.cos(δ) - Math.sin(lat1) * Math.sin(lat2))

    [rad2deg(lat2), rad2deg(lon2)]
  end

  # Génère un quadrilatère GeoJSON autour du segment départ-arrivée
  def corridor_polygon(start_lat, start_lon, end_lat, end_lon, half_width_m = 500)
    brg = bearing(start_lat, start_lon, end_lat, end_lon)

    left_brg  = (brg - 90) % 360
    right_brg = (brg + 90) % 360

    a_left  = destination_point(start_lat, start_lon, half_width_m, left_brg)
    a_right = destination_point(start_lat, start_lon, half_width_m, right_brg)
    b_left  = destination_point(end_lat, end_lon, half_width_m, left_brg)
    b_right = destination_point(end_lat, end_lon, half_width_m, right_brg)

    # Attention : GeoJSON attend [lon, lat]
    coords = [a_left, a_right, b_right, b_left, a_left].map { |lat, lon| [lon, lat] }

    {
      type: "Feature",
      geometry: {
        type: "Polygon",
        coordinates: [coords]
      },
      properties: {}
    }

  end

  def point_in_polygon?(point, polygon)
    x, y = point
      return false if x.nil? || y.nil?
    inside = false
    j = polygon.size - 1

    (0...polygon.size).each do |i|
      xi, yi = polygon[i]
      xj, yj = polygon[j]
      next if xi.nil? || yi.nil? || xj.nil? || yj.nil?
      intersect = ((yi > y) != (yj > y)) &&
                  (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi)
      inside = !inside if intersect
      j = i
    end

    inside
  end

  def classify_pois(pois_in_db)
    # on extrait les noms de POIs pour mon prompt
    list_of_id = pois_in_db.pluck(:id).map do |poi|
      poi = PointOfInterest.find_by_address_id(poi)["name"]
    end
    chat = RubyLLM.chat(model: "gpt-4o").with_params(response_format: { type: 'json_object'})
    prompt = "Here is the list of POIs: #{list_of_id}"
    system_prompt = <<~PROMPT
    Context:
    User will provide a list of Points of Interest (POIs) in GeoJSON format. These POIs will be used to design a pleasant walking itinerary (trendy, photogenic, enjoyable).

    Task:
    Classify the POIs into exactly 4 themes:
    -Theme 1: containing the must-sees POIs to create the most pleasant itinerary
    -Themes 2–4: other themes based on POIs’ nature (e.g., historical, cultural, leisure, food, shopping, nature).

    Rules:
    Each theme must contain 7–10 POIs (never fewer than 7, never more than 10).
    A POI may appear in multiple themes.

    Output format:
    Return pure JSON only (no explanations, no comments, no extra text).
    Top-level key:
    -{ "POIs_collection": [ ... ] }
    -"POIs_collection" must be an array of 4 objects.

    Each object must contain:
    -theme_name (string): 3-5 words summarizing the essence of the itinerary
    -theme_description (string): sentence of 20-30 words to sell the itinerary to the user explaining why this itenerary offers the most pleasant (trendy, photogenic, enjoyable...) trip .
    -points_of_interest (array of 7–10 POI objects)

    Do not include any other keys, metadata, or comments.
    PROMPT
    response = chat.with_instructions(system_prompt).ask(prompt)
    pois_collection = JSON.parse(response.content)["POIs_collection"]
  end

  def generate_POIs(area_for_POIs, pois_in_db)
    # voici le code que j'utilise pour tester dans la colonne: area_for_POIs = corridor_polygon(48.8568781,2.3483592,48.8693002,2.3542855)

    chat = RubyLLM.chat(model: "gpt-4o").with_params(response_format: { type: 'json_object'})
    system_prompt = <<~PROMPT
      Context:
      User will provide:
      - a list of existing Points of Interest (POIs) in an array
      - the number of extra POIs to retrieve
      - a search area in GeoJSON format

      Task:
      1. Retrieve the extra POIs.
        - POIs must be existing, real places inside the search area.
        - They should enhance a pleasant walking itinerary (trendy, photogenic, enjoyable).
        - Include streets, small parks, squares, cafés, galleries, boutiques, and monuments.
        - Prefer authentic, unique, or hidden gems over mainstream tourist attractions.

      2. Classify all POIs (existing + extra) into exactly 4 themes:
        - Theme 1: must-see POIs for the most pleasant itinerary
        - Themes 2–4: other themes by nature (historical, cultural, leisure, food, shopping, nature)

      Output format:
      - Pure JSON only (no text, no explanations, no comments).
      - Top-level keys:
        1. "POIs_collection" = array of 4 objects
          - Each object contains:
            - theme_name (string, 3–5 words)
            - theme_description (string, one sentence, 20–30 words, explaining why this itinerary is enjoyable)
            - poi_names (array of strings: names of all POIs in this theme)
        2. "New_POIs" = array of the extra POIs generated, each including:
            - name (string)
            - address (string)
            - description (string, one sentence, 20–30 words, selling why it is enjoyable)
            - category (string)
      Rules:
      - Exactly 4 themes (no more, no less)
      - Each theme must contain 7–10 POIs (POIs can appear in multiple themes)
      - Do not include any keys, metadata, or fields outside of what is specified
  PROMPT
  pois_in_db = pois_in_db.map do |poi|
    poi = PointOfInterest.find_by_address_id(poi.id)["name"]
  end
  prompt = <<~PROMPT
      Existing list of POIs : #{pois_in_db}
      Number of extra POIs to generate : #{20 - pois_in_db.count}
      Search area for extra POIs to generate : #{area_for_POIs}
      PROMPT
  response = chat.with_instructions(system_prompt).ask(prompt)
  # on filtre les coordonnées des POIs nouvellement créées
  pois_new = JSON.parse(response.content)["New_POIs"]

  access_token = ENV["MAPBOX_API_KEY"]
  pois_new_address = pois_new.map { |poi| poi["address"] }

  pois_new_address_coordinates = Concurrent::Promise.zip(*pois_new_address.map do |poi|
    Concurrent::Promise.execute do
      encoded_poi = CGI.escape(poi)
      uri = URI("https://api.mapbox.com/geocoding/v5/mapbox.places/#{encoded_poi}.json?access_token=#{access_token}")
      res = Net::HTTP.get(uri)
      feature = JSON.parse(res)["features"].first
      {
        "location" => {
          "full_address" => feature["place_name"],
          "latitude" => feature["geometry"]["coordinates"][1],
          "longitude" => feature["geometry"]["coordinates"][0]
        }
      }end
    end).value!

    pois_new_with_location = pois_new.each do |poi|
      pois_new_address_coordinates.each do |poi_location|
        poi["location"] = {
          "full_address" => poi_location["location"]["full_address"],
          "latitude" => poi_location["location"]["latitude"],
          "longitude" => poi_location["location"]["longitude"]
        }
      end
    end
  polygon = area_for_POIs[:geometry][:coordinates].flatten(1)
  pois_inside  = []
  pois_outside = []

  pois_new_with_location.each do |poi|
    lat = poi["location"]["latitude"]
    lon = poi["location"]["longitude"]
    if point_in_polygon?([lon, lat], polygon)
      pois_inside << poi
    else
      pois_outside << poi
    end
  end

  # Crée les addresses et points d'intérêt en db pour les nouveaux POIs
  pois_inside.each do |poi|
    address = Address.create(full_address: poi["location"]["full_address"], latitude: poi["location"]["latitude"], longitude: poi["location"]["longitude"], address_type: "poi")
    point_of_interest = PointOfInterest.create(name: poi["name"], description: poi["description"], category: poi["category"], address: address)
  end

  # Retire les POIs en dehors de la zone
  pois_collections = JSON.parse(response.content)["POIs_collection"]
  pois_collections.each do |collection|
    collection["poi_names"].reject! { |poi_name| pois_outside.include?(poi_name) }
  end
  end
  # END: Code permettant de générer une zone de points d'intérêts
  def order_waypoints(start_lat, start_lon, end_lat, end_lon, filtered_pois)
    url =
    filtered_pois.each do |poi|
     url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/#{start_lat},?access_token=pk.eyJ1IjoidWJhcSIsImEiOiJjbWRwdWV3aXUwZGdyMmtxdzE3ZHB4YjU2In0.Y_ue11FiRja43Jm78jwPvA&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    end
    url = "https://api.mapbox.com/optimized-trips/v1/mapbox/driving/2.3469%2C48.8609%3B2.3522%2C48.8719%3B2.350867%2C48.866582%3B2.370867%2C48.876582?access_token=pk.eyJ1IjoidWJhcSIsImEiOiJjbWRwdWV3aXUwZGdyMmtxdzE3ZHB4YjU2In0.Y_ue11FiRja43Jm78jwPvA&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    ordered_pois_serialized = URI.parse(url).read
    ordered_pois = JSON.parse(ordered_pois_serialized)
  end
end
