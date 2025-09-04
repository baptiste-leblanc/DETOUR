class ItineraryObjectivesController < ApplicationController
  require "json"
  require "uri"
  require 'net/http'
  require 'concurrent-ruby'

def create
  @itinerary_objective = ItineraryObjective.new(itinerary_objective_params)
  @itinerary_objective.user = current_user
  authorize(@itinerary_objective)

  if @itinerary_objective.save
    area_for_POIs = corridor_polygon(@itinerary_objective.departure_address.latitude, @itinerary_objective.departure_address.longitude, @itinerary_objective.arrival_address.latitude, @itinerary_objective.arrival_address.longitude)
    pois_area_coords = area_for_POIs[:geometry][:coordinates].first

    pois_in_db = Address.where(address_type: "poi").in_bounding_box(pois_area_coords)

    departure = @itinerary_objective.departure_address
    arrival = @itinerary_objective.arrival_address
    duration_objective = @itinerary_objective.duration_objective

    if pois_in_db.count > 20
      # situation 1: on a déjà plus de 20 POIs dans la zone donc on va juste les classifier
      filtered_pois_collection = classify_pois(pois_in_db)
      filtered_pois_collection.each do |poi_collection|
        itinerary = Itinerary.create(theme: poi_collection["theme_name"], description: poi_collection["theme_description"], itinerary_objective_id: @itinerary_objective.id)
        poi_coord = []
        poi_collection["points_of_interest"].each do |poi|
          poi_record = PointOfInterest.find_by_name(poi)
          next unless poi_record
          poi_coord << Address.find(PointOfInterest.find_by_name(poi).address_id)
        end
        filtered_pois = pois_adjust(departure, arrival, poi_coord, duration_objective)
        filtered_pois.each do |poi_address|
          point_of_interest = PointOfInterest.find_by_address_id(poi_address.id)
          ItineraryPointOfInterest.create(point_of_interest: point_of_interest, itinerary: itinerary)
        end
      end
    else
      # situation 2: on en a moins donc on va en générer
        # On génère 4 collections d'itinéraraires avec 20 POIs distincts dont certains déjà en DB et d'autres créés
      filtered_pois_collection = generate_POIs(area_for_POIs, pois_in_db)
          # On filtre
      filtered_pois_collection.each do |poi_collection|
        poi_coord = []
        poi_collection["poi_names"].each do |poi_name|
          puts "POIs traités : #{poi_collection['poi_names']}"
          poi = PointOfInterest.find_by(name: poi_name)
          if poi
            poi_coord << Address.find(poi.address_id)
          else
            puts "⚠️ POI introuvable : #{poi_name}"
          end
        end

        itinerary = Itinerary.create(theme: poi_collection["theme_name"], description: poi_collection["theme_description"], itinerary_objective_id: @itinerary_objective.id)

        filtered_pois = pois_adjust(departure, arrival, poi_coord, duration_objective)
        filtered_pois.each do |poi_address|
          point_of_interest = PointOfInterest.find_by_address_id(poi_address.id)
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
      :duration_objective,
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
  def corridor_polygon(start_lat, start_lon, end_lat, end_lon, half_width_m = 200)
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
    -theme_description (string): sentence of 20-25 words to sell the itinerary to the user explaining why this itenerary offers the most pleasant (trendy, photogenic, enjoyable...) trip .
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
            - theme_description (string, one sentence, 20–25 words, explaining why this itinerary is enjoyable)
            - poi_names (array of strings: names of all POIs in this theme)
        2. "New_POIs" = array of the extra POIs generated, each including:
            - name (string)
            - address (string)
            - description (string, one sentence, 20–25 words, selling why it is enjoyable)
            - category (string): one of the following: "Historical Sites", "Culture & Arts", "Museums & Exhibitions", "Religious", "Cafés & Bistros", "Restaurants", "Street Food & Poestry Shop", "Shopping & Leisure", "Nature & Parks", "Knowledge & Institutions"
      Rules:
      - Exactly 4 themes (no more, no less)
      - Each theme must contain 7–10 POIs (POIs can appear in multiple themes)
      - Do not include any keys, metadata, or fields outside of what is specified
  PROMPT
  pois_in_db_names = pois_in_db.map do |poi|
    poi = PointOfInterest.find_by_address_id(poi.id)["name"]
  end
  prompt = <<~PROMPT
      Existing list of POIs : #{pois_in_db_names}
      Number of extra POIs to generate : #{20 - pois_in_db_names.count}
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

    pois_new_with_location = pois_new.each_with_index.map do |poi, index|
      poi_location = pois_new_address_coordinates[index]
      poi["location"] = {
          "full_address" => poi_location["location"]["full_address"],
          "latitude" => poi_location["location"]["latitude"],
          "longitude" => poi_location["location"]["longitude"]
      }
      poi
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
    # 1️⃣ Trouve ou crée l'adresse
    address = Address.find_or_initialize_by(full_address: poi["location"]["full_address"])
    address.latitude = poi["location"]["latitude"]
    address.longitude = poi["location"]["longitude"]
    address.address_type ||= "poi" # ne modifie pas si déjà défini
    address.save! # enregistre ou met à jour

    # 2️⃣ Trouve ou crée le POI
    poi_record = PointOfInterest.find_or_initialize_by(name: poi["name"], address_id: address.id)
    poi_record.description = poi["description"]
    poi_record.category = poi["category"]
    poi_record.save!
  end


  # Retire les POIs en dehors de la zone
  pois_collections = JSON.parse(response.content)["POIs_collection"]

  pois_outside_names = pois_outside.map { |poi| poi["name"] }

  pois_collections.each do |collection|
    collection["poi_names"].reject! { |poi_name| pois_outside_names.include?(poi_name) }
  end
  end
  # END: Code permettant de générer les points d'intérêts dans la zone

  def order_waypoints(start_lat, start_lon, end_lat, end_lon, filtered_pois)
    url =
    filtered_pois.each do |poi|
     url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/#{start_lat},?access_token=pk.eyJ1IjoidWJhcSIsImEiOiJjbWRwdWV3aXUwZGdyMmtxdzE3ZHB4YjU2In0.Y_ue11FiRja43Jm78jwPvA&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    end
    url = "https://api.mapbox.com/optimized-trips/v1/mapbox/driving/2.3469%2C48.8609%3B2.3522%2C48.8719%3B2.350867%2C48.866582%3B2.370867%2C48.876582?access_token=pk.eyJ1IjoidWJhcSIsImEiOiJjbWRwdWV3aXUwZGdyMmtxdzE3ZHB4YjU2In0.Y_ue11FiRja43Jm78jwPvA&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    ordered_pois_serialized = URI.parse(url).read
    ordered_pois = JSON.parse(ordered_pois_serialized)
  end

  def total_duration(departure, arrival, pois)
    api_key = ENV['MAPBOX_API_KEY']
    base_url = "https://api.mapbox.com/directions/v5/mapbox/walking/"
    coordinates = []
    coordinates << "#{departure.longitude},#{departure.latitude};"

    pois.each do |point|
      coordinates << "#{point.longitude},#{point.latitude};"
    end

    coordinates << "#{arrival.longitude},#{arrival.latitude}"

    coordinates << "?alternatives=false&geometries=geojson&overview=full&steps=false&access_token=#{api_key}"
    string_coord = coordinates.join
    url = "#{base_url}#{string_coord}"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    (data["routes"][0]["duration"] / 60.0)
  end

  def itinerary_duration(departure, arrival)
    api_key = ENV['MAPBOX_API_KEY']
    base_url = "https://api.mapbox.com/directions/v5/mapbox/walking/"
    coords = "#{departure.longitude},#{departure.latitude};#{arrival.longitude},#{arrival.latitude}"
    url = "#{base_url}#{coords}?alternatives=false&geometries=geojson&overview=full&steps=false&access_token=#{api_key}"
    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)
    (data["routes"][0]["duration"] / 60.0)
  end

  def pois_adjust(departure, arrival, poi_coord, duration_objective)
  target_duration = duration_objective + itinerary_duration(departure, arrival)
  current_duration = total_duration(departure, arrival, poi_coord)

  return poi_coord if current_duration - target_duration <= 5

  # Tant que trop long
  while current_duration - target_duration > 5 && poi_coord.any?
    # Supprime le POI qui augmente le moins la durée totale (ou random si tu veux)
    poi_to_remove = poi_coord.min_by do |poi|
      total_duration(departure, arrival, poi_coord - [poi])
    end
    poi_coord.delete(poi_to_remove)
    current_duration = total_duration(departure, arrival, poi_coord)
  end

  poi_coord
  end
end
