class ItineraryObjective < ApplicationRecord
  belongs_to :departure_address, class_name: "Address"
  belongs_to :arrival_address, class_name: "Address"
  belongs_to :user
  has_many :itineraries
end
