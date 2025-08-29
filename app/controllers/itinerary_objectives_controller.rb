class ItineraryObjectivesController < ApplicationController
  require "json"
  require "uri"

  def create

    @itinerary_objective = ItineraryObjective.new(itinerary_objective_params)
    @itinerary_objective.user = current_user
    authorize(@itinerary_objective)

    count = 0
    if @itinerary_objective.save
      filtered_pois_collection = generate_POIs(@itinerary_objective.departure_address.latitude, @itinerary_objective.departure_address.longitude, @itinerary_objective.arrival_address.latitude, @itinerary_objective.arrival_address.longitude)
      filtered_pois_collection.each do |poi_collection|

        itinerary = Itinerary.create(theme: poi_collection["theme_name"], description: poi_collection["theme_description"], itinerary_objective_id: @itinerary_objective.id)
        poi_collection["points_of_interest"].each do |poi|
          address = Address.create(full_address: poi["location"]["full_address"], latitude: poi["location"]["latitude"], longitude: poi["location"]["longitude"])
          point_of_interest = PointOfInterest.create(name: poi["name"], description: poi["description"], category: poi["category"], address: address)
          ItineraryPointOfInterest.create(point_of_interest: point_of_interest, itinerary: itinerary)
        end


        @itinerary = itinerary if count == 0
        count += 1
      end
      redirect_to best_itinerary_itinerary_objective_itineraries_path(@itinerary_objective)
    else
      redirect_to itinerary_objective_path
    end
  end
  end


  # def edit
  #   @itinerary_objective = ItineraryObjective.find(params[:id])
  #   authorize @itinerary_objective
  # end

  # def update
  #   @itinerary_objective = ItineraryObjective.find(params[:id])
  #   authorize @itinerary_objective


  #   if @itinerary_objective.update(address_params)
  #     redirect_to @itinerary_objective
  #   else
  #     render :edit
  #   end
  # end

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

  def generate_POIs(start_lat, start_lon, end_lat, end_lon)
    chat = RubyLLM.chat(model: "gpt-4o").with_params(response_format: { type: 'json_object'})
    system_prompt = <<~PROMPT
      Rules:
      1. Point of interest (POI) definition (mandatory):
      A POI is not limited to monuments or museums: it can also be a street, park, square, dead end, passageway, bridge, public place, natural spot, restaurant, café, or shop.
      Always prioritize outstanding, visually attractive, and photogenic POIs that enhance the enjoyment of the route.
      The ultimate goal is to make the itinerary as aesthetic, memorable, and camera‑worthy as possible.
      2. Geographical constraint (mandatory):
      Only return POIs strictly inside the rectangle defined by the 4 coordinates, given by Mapbox.
      Exclude any POI outside or exactly on the rectangle’s edges.
      The midpoint of the edge between points 1 and 2 = departure point.
      The midpoint of the edge between points 3 and 4 = arrival point.
      Never extrapolate, infer or approximate locations: use only validated POIs inside the rectangle.
      3. Theme constraint (optional):
      If a "theme" field is provided, return only POIs coherent with both the theme and the POI definition constraint.
      If no "theme" is provided, return only POIs relevant to the "best POIs" theme.
      4. Quantity constraint:
      Each theme must contain between 5 and 15 POIs inclusive.
      Never return fewer than 5 or more than 15 POIs per theme.
      If there are fewer than 5 valid POIs inside the rectangle for a theme, that theme must be omitted and replaced by another coherent category (to always ensure 4 themes with 5–15 POIs each).
      Never invent, hallucinate, or approximate data.
      5. Data format constraint:
      POIs must be grouped into exactly 4 themes:
      - Theme 1: "best POIs" (mandatory, first group, containing the top photogenic POIs).
      - Themes 2–4: categories based on POIs’ nature (e.g., historical, cultural, leisure, food, shopping, nature).
      Each theme must include:
      - theme_name (string, ≤7 words; the first must be "best POIs")
      - theme_description (string, ≤12 words)
      - points_of_interest (array of 5–15 POI objects)
      Each POI must include exactly:
      - name (string)
      - location (object) containing: full_address (string), latitude (float) and longitude (float)
      - description (string, ≤15 words, concise)
      - category (string)
      6. Output constraint:
      The output must be pure JSON only (no explanations, no comments, no text before/after).
      The top-level key must be { "POIs_collection": [ ... ] }
      "POIs_collection" must be an array of 4 theme objects.
      Each theme object must have theme_name, theme_description, and points_of_interest.
      "points_of_interest" must be an array of 5-15 POI objects.
      Do not include any other keys, metadata, or comments.
  PROMPT
  area_for_POIs = corridor_polygon(start_lat, start_lon, end_lat, end_lon)
# voici le code que j'utilise pour tester dans la colonne: area_for_POIs = corridor_polygon(48.8568781,2.3483592,48.8693002,2.3542855)
  prompt = "To enjoy my itinerary, I need some points of interests located inside the rectangle whose 4 corners are represented by the 4 first coordinates below : #{area_for_POIs}"
  response = chat.with_instructions(system_prompt).ask(prompt)
  pois_collection = JSON.parse(response.content)["POIs_collection"]
  polygon = area_for_POIs[:geometry][:coordinates].flatten(1)
  filtered_pois_collection = pois_collection.each do |poi_collection|
    poi_collection["points_of_interest"].select do |poi|
      lat = poi["location"]["latitude"]
      lon = poi["location"]["longitude"]
      point_in_polygon?([lon, lat], polygon)
    end
  end
  end

  # END: Code permettant de générer une zone de points d'intérêts
 # BAPTISTE BOUGER EN SHOW d'itinerary
  def order_waypoints(start_lat, start_lon, end_lat, end_lon, filtered_pois)
    url =
    filtered_pois.each do |poi|
     url = "https://api.mapbox.com/optimized-trips/v1/mapbox/walking/#{start_lat},?access_token=pk.eyJ1IjoidWJhcSIsImEiOiJjbWRwdWV3aXUwZGdyMmtxdzE3ZHB4YjU2In0.Y_ue11FiRja43Jm78jwPvA&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    end
    url = "https://api.mapbox.com/optimized-trips/v1/mapbox/driving/2.3469%2C48.8609%3B2.3522%2C48.8719%3B2.350867%2C48.866582%3B2.370867%2C48.876582?access_token=pk.eyJ1IjoidWJhcSIsImEiOiJjbWRwdWV3aXUwZGdyMmtxdzE3ZHB4YjU2In0.Y_ue11FiRja43Jm78jwPvA&overview=full&geometries=geojson&roundtrip=false&source=first&destination=last"
    ordered_pois_serialized = URI.parse(url).read
    ordered_pois = JSON.parse(ordered_pois_serialized)
  end
