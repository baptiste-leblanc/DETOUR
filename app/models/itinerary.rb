class Itinerary < ApplicationRecord
  belongs_to :itinerary_objective
  has_many :point_of_interests, through: :itinerary_point_of_interests
end
