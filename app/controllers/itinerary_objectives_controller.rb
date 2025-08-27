class ItineraryObjectivesController < ApplicationController
  def create
    @itinerary_objective = ItineraryObjective.new(itinerary_objective_params)
    if @itinerary_objective.save
      redirect_to itinerary_objective_path, notice: "DOne"
    else
      redirect_to itinerary_objective_path, alert: "Error"
    end
  end

  def 

  def edit
    @address = Address.find(address_params)
    @address.save
  end

  def update
    @address = Address.find(address_params)
  end

  private

  def itinerary_objective_params
    params.require(:itinerary_objective).permit(
      departure_address_attributes: [:id, :full_address],
      arrival_address_attributes: [:id, :full_address]
    )
  end
end
