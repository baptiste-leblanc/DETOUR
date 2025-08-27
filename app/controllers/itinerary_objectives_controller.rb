class ItineraryObjectivesController < ApplicationController
  def edit
    @address = address.find(address_params)
    @address.save
  end

  def update
    @address = address.find(address_params)
  end

  private

  def address_params
    params.require(:address).permit(:longitude, :latitude)
  end
end
