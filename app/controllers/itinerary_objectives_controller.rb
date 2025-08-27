class ItineraryObjectivesController < ApplicationController
  def edit
    @address = Address.find(params[:id])
  end

  def update
    @address = Address.find(params[:id])

    if @address.update(address_params)
      redirect_to @address
    else
      render :edit
    end
  end

  private

  def address_params
    params.require(:address).permit(:longitude, :latitude)
  end
end
