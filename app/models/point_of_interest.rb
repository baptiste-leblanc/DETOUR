class PointOfInterest < ApplicationRecord
  belongs_to :address
  has_many :itineraries, through: :itinerary_point_of_interests

  accepts_nested_attributes_for :address
end
