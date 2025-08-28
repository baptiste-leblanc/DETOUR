class ItineraryObjectivesController < ApplicationController
  require "json"
  require "uri"

  def create
    @itinerary_objective = ItineraryObjective.new(itinerary_objective_params)
    @itinerary_objective.user = current_user
    authorize(@itinerary_objective)

    if @itinerary_objective.save
      redirect_to itinerary_objective_path(@itinerary_objective), notice: "Done"
    else
      redirect_to itinerary_objective_path, alert: "Error"
    end

    pois = generate_POIs(@itinerary_objective.departure_address.latitude, @itinerary_objective.departure_address.longitude, @itinerary_objective.arrival_address.latitude, @itinerary_objective.arrival_address.longitude)
    pois.each do |poi|
      Point_of_interest.create(name: poi.name)
    raise
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
      Role:
      You are a guide that provides points of interest (POIs) located strictly inside a geographical area defined by Mapbox.
      The area is always a polygonal rectangle defined by 4 latitude/longitude coordinates. The input coordinates data will be 5 points. The 5th coordinates represents the 1st point in order to form a closed rectangle.
      A POI is not necessarily a museum or a monument — it may also be a restaurant, store, café, park, or even a pleasant street — but it must always satisfy the geographical constraint. Your recommandation should focus more on outstanding places in terms of their aesthetics rather than museums and monuments. The final objective is to make the walk on the itinerary as enjoyable and photogenic as possible.
      Rules:
      1. Geographical constraint (mandatory):
      - Only return POIs whose latitude and longitude are strictly inside the polygonal rectangle defined by the 4 coordinates. This rectangle is a bounding box with these 4 connecting points that forms a closed rectangle.
      - Discard any POI located outside or exactly on the edge of the rectangle. The middle of the edge formed by the connection of the 1st and the 2nd points correspounds to the point of departure. The middle of the edge formed by the connection of the 3rd and the 4th points correspounds to the point of arrival.
      - Do not extrapolate or infer locations: use only validated POIs inside the area.
      2. Theme constraint (optional):
      - If a "theme" field is provided, return only POIs that are coherent with the theme.
      - If no theme is provided, return relevant POIs without thematic filtering.
      3. Quantity constraint:
      - Return between 10 and 15 POIs.
      - If fewer than 10 valid POIs exist inside the rectangle, return only those found.
      - Never invent, hallucinate, or approximate data.
      4. Data format constraint:
      Each POI must be represented as an object with exactly the following fields:
      - name (string)
      - location (object) containing: full_address (string), latitude (float), longitude ( float)
      - description (string, maximum 15 words, short and concise)
      - category (string)
      5. Output constraint:
      - The response must be in JSON format, the outcome is directly a valid JSON object, with a single top-level key: "points_of_interest", and without any text before. Thus, this output must be given directly as input to Mapbox which can interpretated it.
      - "points_of_interest" must be an array of POI objects.
      - Do not include any additional keys, metadata, explanations, or text before/after the JSON.
  PROMPT
  area_for_POIs = corridor_polygon(start_lat, start_lon, end_lat, end_lon)
# voici le code que j'utilise pour tester dans la colonne: area_for_POIs = corridor_polygon(48.8568781,2.3483592,48.8693002,2.3542855)
  prompt =  "To enjoy my itinerary, I need some points of interests located inside the rectangle whose 4 corners are represented by the 4 first coordinates below : #{area_for_POIs}"
  response = chat.with_instructions(system_prompt).ask(prompt)
  pois = JSON.parse(response.content)["points_of_interest"]
  polygon = area_for_POIs[:geometry][:coordinates].flatten(1)
  filtered_pois = pois.select do |poi|
    lat = poi["location"]["latitude"]
    lon = poi["location"]["longitude"]
    point_in_polygon?([lon, lat], polygon)
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
