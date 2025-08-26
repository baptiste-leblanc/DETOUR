# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# destroy_all
User.destroy_all
Address.destroy_all
Itinerary.destroy_all
ItineraryObjective.destroy_all
ItineraryPointOfInterest.destroy_all
PointOfInterest.destroy_all

# Users
# user = User.new(email: "test@test.com", password: "password")
user1 = User.create!(email: "marie.audrey@yopmail.com", password: "password123")
# user1.save
# user2 = User.create!(email: "jon.snow@example.com", password: "secure456")
# user2.save
puts 'Users created'

# Addresses
addr_wagon     = Address.create!(full_address: "16 Villa Gaudelet, 75011 Paris", latitude: 48.864716, longitude: 2.379700)
addr_rivoli     = Address.create!(full_address: "10 Rue de Rivoli, Paris", latitude: 48.855, longitude: 2.360)
addr_louvre     = Address.create!(full_address: "Rue de Rivoli, 75001 Paris (Louvre)", latitude: 48.8606, longitude: 2.3376)
addr_toureiffel = Address.create!(full_address: "Champ de Mars, 75007 Paris", latitude: 48.8584, longitude: 2.2945)
addr_montmartre = Address.create!(full_address: "Butte Montmartre, 75018 Paris", latitude: 48.8867, longitude: 2.3431)
addr_luxembourg = Address.create!(full_address: "Jardin du Luxembourg, 75006 Paris", latitude: 48.8462, longitude: 2.3372)
addr_invalides  = Address.create!(full_address: "Esplanade des Invalides, 75007 Paris", latitude: 48.8566, longitude: 2.3134)
puts 'Addresses created'

# Itinerary Objectives
objective1 = ItineraryObjective.create!(
  name: "Balade rapide Louvre - Rivoli",
  departure_address_id: addr_louvre.id,
  arrival_address_id: addr_rivoli.id,
  duration_objective: 1800,   # 30 minutes
  user_id: user1.id
)
objective2 = ItineraryObjective.create!(
  name: "Tour express Tour Eiffel",
  departure_address_id: addr_invalides.id,
  arrival_address_id: addr_toureiffel.id,
  duration_objective: 3600,   # 1h
  user_id: user1.id
)
objective3 = ItineraryObjective.create!(
  name: "Promenade Montmartre",
  departure_address_id: addr_wagon.id,
  arrival_address_id: addr_montmartre.id,
  duration_objective: 2700,   # 45 min
  user_id: user1.id
)
puts 'Itinerary objectives created'

# Itineraries
itinerary1 = Itinerary.create!(
  duration: 1800,   # 30 min
  theme: "Musées",
  itinerary_objective_id: objective1.id
)
itinerary2 = Itinerary.create!(
  duration: 3600,   # 1h
  theme: "Monuments emblématiques",
  itinerary_objective_id: objective2.id
)
itinerary3 = Itinerary.create!(
  duration: 2700,   # 45 min
  theme: "Quartier pittoresque",
  itinerary_objective_id: objective3.id
)
puts 'Itineraries created'

# Points of Interest
poi_louvre = PointOfInterest.create!(
  name: "Musée du Louvre",
  address_id: addr_louvre.id,
  description: "Musée incontournable au cœur de Paris",
  category: "Culture"
)

poi_nd = PointOfInterest.create!(
  name: "Cathédrale Notre-Dame",
  address_id: addr_rivoli.id,
  description: "Chef-d'œuvre gothique",
  category: "Monument"
)

poi_eiffel = PointOfInterest.create!(
  name: "Tour Eiffel",
  address_id: addr_toureiffel.id,
  description: "Symbole de Paris",
  category: "Monument"
)

poi_montmartre = PointOfInterest.create!(
  name: "Sacré-Cœur",
  address_id: addr_montmartre.id,
  description: "Vue panoramique sur Paris",
  category: "Monument"
)

poi_luxembourg = PointOfInterest.create!(
  name: "Jardin du Luxembourg",
  address_id: addr_luxembourg.id,
  description: "Un havre de verdure au cœur de Paris",
  category: "Nature"
)
puts 'Points of interests created'

# --- Jointures (Itinerary ↔ POI) ---
# Itinéraire 1 : Louvre + Notre-Dame (30 min)
ItineraryPointOfInterest.create!(itinerary_id: itinerary1.id, point_of_interest_id: poi_louvre.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary1.id, point_of_interest_id: poi_nd.id)

# Itinéraire 2 : Tour Eiffel uniquement (1h)
ItineraryPointOfInterest.create!(itinerary_id: itinerary2.id, point_of_interest_id: poi_eiffel.id)

# Itinéraire 3 : Montmartre + Jardin du Luxembourg (45 min)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_montmartre.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_luxembourg.id)
puts 'Itinerary - POI joints created'
