class PagesController < ApplicationController
  def home
    @itinerary_objective = ItineraryObjective.new
  end
end
