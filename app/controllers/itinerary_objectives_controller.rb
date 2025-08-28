class ItineraryObjectivesController < ApplicationController
  require "json"
  require "uri"

  def create
    @itinerary_objective = ItineraryObjective.new(itinerary_objective_params)
    @itinerary_objective.user = current_user
    authorize(@itinerary_objective)

    if @itinerary_objective.save
      filtered_pois_collection = generate_POIs(@itinerary_objective.departure_address.latitude, @itinerary_objective.departure_address.longitude, @itinerary_objective.arrival_address.latitude, @itinerary_objective.arrival_address.longitude)
      filtered_pois_collection.each do |poi_collection|
        poi_collection["points_of_interest"].each do |poi|
          address = Address.create(full_address: poi["location"]["full_address"], latitude: poi["location"]["latitude"], longitude: poi["location"]["longitude"])
          PointOfInterest.create(name: poi["name"], description: poi["description"], category: poi["category"], address: address)
        end
        itinerary = Itinerary.create(theme: poi_collection["theme_name"])
        @itinerary = itinerary if poi_collection["theme_name"] == "best POIs"
      end
      redirect_to itinerary_objective_itinerary_path(@itinerary_objective, @itinerary), notice: "Done"
    else
      redirect_to itinerary_objective_path, alert: "Error"
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
        1. Geographical constraint (mandatory):
        Only return POIs strictly inside the rectangle defined by the 4 coordinates, given by Mapbox.
        Exclude any POI outside or exactly on the rectangle edges.
        The middle of the edge between points 1 and 2 is the departure point.
        The middle of the edge between points 3 and 4 is the arrival point.
        Never extrapolate or infer locations: use only validated POIs inside the area.
        2. Theme constraint (optional):
        If a "theme" field is provided, return only POIs coherent with the theme.
        If no "theme" is provided, return relevant POIs without thematic filtering.
        3. Quantity constraint:
        Return 10 to 15 POIs.
        If fewer than 10 valid POIs exist inside the rectangle, return only those found.
        Never invent, hallucinate, or approximate data.
        4. Data format constraint:
        POIs must be grouped into exactly 4 themes:
        - Theme 1: "best POIs" (mandatory, first group)
        - Themes 2 to 4: categories based on POIs nature (e.g., historical, shopping, food, leisure, culture).
        Each theme must include:
        - theme_name (string, ≤7 words; the first must be "best POIs")
        - theme_description (string, ≤12 words)
        - points_of_interest (array of POI objects)
        Each POI must include exactly:
        - name (string)
        - location (object) containing: full_address (string), latitude (float) and longitude (float)
        - description (string, ≤15 words, concise)
        - category (string)
        5. Output constraint:
        The response must be pure JSON, with no text, introduction, or explanation before or after.
        The top-level key must be "POIs_collection".
        "POIs_collection" must be an array of 4 theme objects.
        Each theme object must have theme_name, theme_description, and points_of_interest.
        "points_of_interest" must be an array of POI objects.
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
