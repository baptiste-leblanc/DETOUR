class Address < ApplicationRecord
  has_one :itinerary_objectives, dependent: :destroy
end
