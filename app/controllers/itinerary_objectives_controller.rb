class ItineraryObjectivesController < ApplicationController
  def create
    @itinerary_objective = ItineraryObjective.new(itinerary_objective_params)
    if @itinerary_objective.save
      redirect_to edit_itinerary_objective_path(@itinerary_objective), notice: "Done"
    else
      redirect_to itinerary_objective_path, alert: "Error"
    end
  end

  def edit
    @itinerary_objective = ItineraryObjective.find(params[:id])
    authorize @itinerary_objective
  end

  def update
    @itinerary_objective = ItineraryObjective.find(params[:id])
    authorize @itinerary_objective


    if @itinerary_objective.update(address_params)
      redirect_to @itinerary_objective
    else
      render :edit
    end
  end

  private

  def itinerary_objective_params
    params.require(:itinerary_objective).permit(
      departure_address_attributes: [:id, :full_address],
      arrival_address_attributes: [:id, :full_address]
    )
  end

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
end
