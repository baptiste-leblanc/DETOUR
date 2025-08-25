class ItineraryPointOfInterest < ApplicationRecord
  belongs_to :itinerary
  belongs_to :point_of_interest
end
