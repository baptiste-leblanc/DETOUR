class Address < ApplicationRecord
  has_one :departure_itinerary_objectives,
           class_name: "ItineraryObjective",
           foreign_key: "departure_address_id",
           dependent: :nullify

  has_one :arrival_itinerary_objectives,
           class_name: "ItineraryObjective",
           foreign_key: "arrival_address_id",
           dependent: :nullify

  has_many :point_of_interests, dependent: :destroy
end
