class Address < ApplicationRecord
  geocoded_by :full_address
  after_validation :geocode, if: :will_save_change_to_full_address?

  has_one :departure_itinerary_objectives,
           class_name: "ItineraryObjective",
           foreign_key: "departure_address_id",
           dependent: :nullify

  has_one :arrival_itinerary_objectives,
           class_name: "ItineraryObjective",
           foreign_key: "arrival_address_id",
           dependent: :nullify

  has_one :point_of_interests,
           class_name: "PointOfInterest",
           foreign_key: "address_id",
           dependent: :nullify

end
