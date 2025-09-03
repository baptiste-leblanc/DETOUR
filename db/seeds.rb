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
ItineraryPointOfInterest.destroy_all
Itinerary.destroy_all
ItineraryObjective.destroy_all
User.destroy_all
PointOfInterest.destroy_all
Address.destroy_all

# Users
user1 = User.create!(email: "test@test.com", password: "password")
puts 'Users created'

# Addresses
addr_wagon     = Address.create!(full_address: "16 Villa Gaudelet, 75011 Paris", latitude: 48.864716, longitude: 2.379700)
addr_rivoli     = Address.create!(full_address: "10 Rue de Rivoli, Paris", latitude: 48.855, longitude: 2.360)
addr_louvre     = Address.create!(full_address: "Rue de Rivoli, 75001 Paris (Louvre)", latitude: 48.8606, longitude: 2.3376)
addr_toureiffel = Address.create!(full_address: "Champ de Mars, 75007 Paris", latitude: 48.8584, longitude: 2.2945)
addr_montmartre = Address.create!(full_address: "Butte Montmartre, 75018 Paris", latitude: 48.8867, longitude: 2.3431)
addr_luxembourg = Address.create!(full_address: "Jardin du Luxembourg, 75006 Paris", latitude: 48.8462, longitude: 2.3372)
addr_invalides  = Address.create!(full_address: "Esplanade des Invalides, 75007 Paris", latitude: 48.8566, longitude: 2.3134)
addr_cirque = Address.create!(
  full_address: "110 Rue Amelot, 75011 Paris, France",
  latitude: 48.8633,
  longitude: 2.36723,
  address_type: "poi"
)

addr_temple = Address.create!(
  full_address: "64 Rue de Bretagne, 75003 Paris, France",
  latitude: 48.86448,
  longitude: 2.36072,
  address_type: "poi"
)

addr_cain = Address.create!(
  full_address: "8 Rue Payenne, 75003 Paris, France",
  latitude: 48.85806,
  longitude: 2.36273,
  address_type: "poi"
)

addr_sale = Address.create!(
  full_address: "94 Rue Vieille du Temple, 75003 Paris, France",
  latitude: 48.86021,
  longitude: 2.36163,
  address_type: "poi"
)

addr_breizh = Address.create!(
  full_address: "109 Rue Vieille du Temple, 75003 Paris, France",
  latitude: 48.86062,
  longitude: 2.3618,
  address_type: "poi"
)

addr_rosiers = Address.create!(
  full_address: "10 Rue des Rosiers, 75004 Paris, France",
  latitude: 48.85729,
  longitude: 2.36022,
  address_type: "poi"
)

addr_hanoi = Address.create!(
  full_address: "19 Rue Ferdinand Duval, 75004 Paris, France",
  latitude: 48.85693,
  longitude: 2.35972,
  address_type: "poi"
)

addr_annefrank = Address.create!(
  full_address: "14 Imp. Berthaud, 75003 Paris, France",
  latitude: 48.86161,
  longitude: 2.35498,
  address_type: "poi"
)

addr_rue_rosiers = Address.create!(
  full_address: "Rue des Rosiers, 75004 Paris, France",
  latitude: 48.85703,
  longitude: 2.35969,
  address_type: "poi"
)

addr_tresor = Address.create!(
  full_address: "Rue du Trésor, 75004 Paris, France",
  latitude: 48.85727,
  longitude: 2.35735,
  address_type: "poi"
)

addr_mmmozza = Address.create!(
  full_address: "57 Rue de Bretagne, 75003 Paris, France",
  latitude: 48.86387,
  longitude: 2.3606,
  address_type: "poi"
)

addr_enfantsrouges = Address.create!(
  full_address: "37 Rue Charlot, 75003 Paris, France",
  latitude: 48.86275,
  longitude: 2.362,
  address_type: "poi"
)

addr_glaces = Address.create!(
  full_address: "63 Rue de Bretagne, 75003 Paris, France",
  latitude: 48.86412,
  longitude: 2.3601,
  address_type: "poi"
)

addr_barres = Address.create!(
  full_address: "Rue des Barres, 75004 Paris, France",
  latitude: 48.85534,
  longitude: 2.35526,
  address_type: "poi"
)

addr_bretonnerie = Address.create!(
  full_address: "Rue Sainte-Croix de la Bretonnerie, 75004 Paris, France",
  latitude: 48.85838,
  longitude: 2.35561,
  address_type: "poi"
)

addr_montmorency = Address.create!(
  full_address: "Rue de Montmorency, 75003 Paris, France",
  latitude: 48.86307,
  longitude: 2.35512,
  address_type: "poi"
)

addr_ambroise = Address.create!(
  full_address: "71 bis Bd Voltaire, 75011 Paris, France",
  latitude: 48.86118,
  longitude: 2.37567,
  address_type: "poi"
)

addr_carreau = Address.create!(
  full_address: "4 Rue Eugène Spuller, 75003 Paris, France",
  latitude: 48.86461,
  longitude: 2.36231,
  address_type: "poi"
)

addr_picasso = Address.create!(
  full_address: "5 Rue de Thorigny, 75003 Paris, France",
  latitude: 48.85987,
  longitude: 2.36228,
  address_type: "poi"
)

addr_saintpaul = Address.create!(
  full_address: "99 Rue Saint-Antoine, 75004 Paris, France",
  latitude: 48.85446,
  longitude: 2.36145,
  address_type: "poi"
)

puts 'Addresses created'

# Itinerary Objectives
objective1 = ItineraryObjective.create!(
  name: "Historic & Cultural Heart of Paris",
  departure_address_id: addr_louvre.id,
  arrival_address_id: addr_rue_rosiers.id,  # Fin du parcours Rue des Rosiers
  duration_objective: 3600,   # 1h
  user_id: User.first.id
)

objective2 = ItineraryObjective.create!(
  name: "Iconic Monuments",
  departure_address_id: addr_invalides.id,
  arrival_address_id: addr_toureiffel.id,
  duration_objective: 3600,   # 1h
  user_id: User.first.id
)

objective3 = ItineraryObjective.create!(
  name: "Marais Food & Gardens",
  departure_address_id: addr_cirque.id,
  arrival_address_id: addr_glaces.id,  # Fin du parcours Glaces Moustache
  duration_objective: 5400,   # 1h30
  user_id: User.first.id
)

puts 'Itinerary objectives created'

# Itineraries
itinerary1 = Itinerary.create!(
  duration: 3600,   # 1h
  theme: "Historic & Cultural Heart of Paris",
  description: "A walking tour through Paris’s iconic museums, historic streets, and cultural landmarks in the heart of the city.",
  itinerary_objective_id: objective1.id
)

itinerary2 = Itinerary.create!(
  duration: 3600,   # 1h
  theme: "Iconic Monuments",
  description: "Explore Paris’s most famous monuments and architectural marvels, from the Eiffel Tower to Saint-Paul Saint-Louis Church.",
  itinerary_objective_id: objective2.id
)

itinerary3 = Itinerary.create!(
  duration: 5400,   # 1h30
  theme: "Marais Food & Gardens",
  description: "A delightful stroll through the Marais, combining charming gardens, historic streets, and the best local food spots.",
  itinerary_objective_id: objective3.id
)

puts 'Itineraries created'

# Points of Interest

poi_louvre = PointOfInterest.create!(
  name: "Musée du Louvre",
  address_id: addr_louvre.id,
  description: "One of the world's largest and most visited museums, showcasing iconic art from multiple eras.",
  category: "Museums & Exhibitions"
)

poi_nd = PointOfInterest.create!(
  name: "Cathédrale Notre-Dame",
  address_id: addr_rivoli.id,
  description: "A masterpiece of Gothic architecture, famous for its intricate façade and stunning stained glass windows.",
  category: "Religious"
)

poi_eiffel = PointOfInterest.create!(
  name: "Tour Eiffel",
  address_id: addr_toureiffel.id,
  description: "Paris’s iconic iron tower, offering panoramic city views from its observation decks.",
  category: "Historical Sites"
)

poi_montmartre = PointOfInterest.create!(
  name: "Sacré-Cœur",
  address_id: addr_montmartre.id,
  description: "A striking basilica perched on Montmartre hill, providing breathtaking views over Paris.",
  category: "Religious"
)

poi_luxembourg = PointOfInterest.create!(
  name: "Jardin du Luxembourg",
  address_id: addr_luxembourg.id,
  description: "A lush and elegant garden in the heart of Paris, perfect for leisurely walks and relaxation.",
  category: "Nature & Parks"
)

poi_cirque = PointOfInterest.create!(
  name: "Cirque d'Hiver Bouglione",
  address_id: addr_cirque.id,
  description: "A historic 19th-century circus venue hosting acrobatics, concerts, and cultural performances in a grand rotunda.",
  category: "Culture & Arts"
)

poi_temple = PointOfInterest.create!(
  name: "Square du Temple",
  address_id: addr_temple.id,
  description: "A charming landscaped park with a pond, lawns, and shaded benches in the lively Haut-Marais district.",
  category: "Nature & Parks"
)

poi_cain = PointOfInterest.create!(
  name: "Square Georges-Cain",
  address_id: addr_cain.id,
  description: "A tranquil green space featuring sculptures, benches, and views of Hôtel de Saint-Aignan.",
  category: "Nature & Parks"
)

poi_sale = PointOfInterest.create!(
  name: "Jardin de l'Hôtel-Salé-Léonor-Fini",
  address_id: addr_sale.id,
  description: "A hidden garden next to the Picasso Museum, ideal for a quiet break in the Marais.",
  category: "Nature & Parks"
)

poi_breizh = PointOfInterest.create!(
  name: "Breizh Café Marais",
  address_id: addr_breizh.id,
  description: "A popular Breton crêperie blending tradition and modern flavors in a stylish Parisian setting.",
  category: "Restaurants"
)

poi_rosiers = PointOfInterest.create!(
  name: "Jardin des Rosiers",
  address_id: addr_rosiers.id,
  description: "A secluded garden behind the Marais façades, filled with rose bushes and quiet pathways.",
  category: "Nature & Parks"
)

poi_hanoi = PointOfInterest.create!(
  name: "Hanoi Corner",
  address_id: addr_hanoi.id,
  description: "A cozy spot offering authentic Vietnamese specialties in the heart of the Marais.",
  category: "Restaurants"
)

poi_annefrank = PointOfInterest.create!(
  name: "Jardin Anne Frank",
  address_id: addr_annefrank.id,
  description: "A peaceful garden dedicated to Anne Frank, combining modern landscaping with a historic dovecote.",
  category: "Nature & Parks"
)

poi_rue_rosiers = PointOfInterest.create!(
  name: "Rue des Rosiers",
  address_id: addr_rue_rosiers.id,
  description: "The bustling heart of the Jewish quarter, lined with historic bakeries, delis, and boutiques.",
  category: "Historical Sites"
)

poi_tresor = PointOfInterest.create!(
  name: "Rue du Trésor",
  address_id: addr_tresor.id,
  description: "A picturesque cobbled street lined with terraces and boutiques, hidden in the Marais.",
  category: "Historical Sites"
)

poi_mmmozza = PointOfInterest.create!(
  name: "Mmmozza..!",
  address_id: addr_mmmozza.id,
  description: "A gourmet deli dedicated to fresh Italian mozzarella and artisanal products.",
  category: "Cafés & Bistros"
)

poi_enfantsrouges = PointOfInterest.create!(
  name: "Marché des Enfants-Rouges",
  address_id: addr_enfantsrouges.id,
  description: "Paris’s oldest covered market, offering street food, fresh produce, and multicultural specialties.",
  category: "Street Food & Poestry Shop"
)

poi_glaces = PointOfInterest.create!(
  name: "Glaces Moustache",
  address_id: addr_glaces.id,
  description: "A playful ice cream shop serving artisanal flavors with a creative twist.",
  category: "Cafés & Bistros"
)

poi_barres = PointOfInterest.create!(
  name: "Rue des Barres",
  address_id: addr_barres.id,
  description: "A charming medieval street beside Saint-Gervais, lined with cafés and historic facades.",
  category: "Historical Sites"
)

poi_bretonnerie = PointOfInterest.create!(
  name: "Rue Sainte-Croix de la Bretonnerie",
  address_id: addr_bretonnerie.id,
  description: "A lively Marais street known for its eclectic shops, historic buildings, and cafés.",
  category: "Shopping & Leisure"
)

poi_montmorency = PointOfInterest.create!(
  name: "Rue de Montmorency",
  address_id: addr_montmorency.id,
  description: "One of the oldest streets in Paris, home to the 15th-century house of Nicolas Flamel.",
  category: "Historical Sites"
)

poi_ambroise = PointOfInterest.create!(
  name: "Église Saint-Ambroise",
  address_id: addr_ambroise.id,
  description: "A neo-Romanesque church from the 19th century, featuring striking twin towers and ornate interiors.",
  category: "Religious"
)

poi_carreau = PointOfInterest.create!(
  name: "Le Carreau du Temple",
  address_id: addr_carreau.id,
  description: "A restored 19th-century market hall now hosting cultural events, markets, and exhibitions.",
  category: "Culture & Arts"
)

poi_picasso = PointOfInterest.create!(
  name: "Musée Picasso",
  address_id: addr_picasso.id,
  description: "A celebrated museum dedicated to Pablo Picasso’s works, housed in the elegant Hôtel Salé.",
  category: "Museums & Exhibitions"
)

poi_saintpaul = PointOfInterest.create!(
  name: "Église Saint-Paul Saint-Louis",
  address_id: addr_saintpaul.id,
  description: "A 17th-century Jesuit church with a grand baroque façade and richly decorated interiors.",
  category: "Religious"
)

poi_invalides = PointOfInterest.create!(
  name: "Les Invalides",
  address_id: addr_invalides.id,
  description: "A historic complex housing museums, monuments, and Napoleon’s tomb, showcasing France’s military history.",
  category: "Historical Sites"
)

puts 'Points of interests created'

# --- Jointures (Itinerary ↔ POI) ---
# Itinerary 1 : Historic & Cultural Heart of Paris
ItineraryPointOfInterest.create!(itinerary_id: itinerary1.id, point_of_interest_id: poi_louvre.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary1.id, point_of_interest_id: poi_nd.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary1.id, point_of_interest_id: poi_tresor.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary1.id, point_of_interest_id: poi_rue_rosiers.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary1.id, point_of_interest_id: poi_picasso.id)

# Itinerary 2 : Iconic Monuments
ItineraryPointOfInterest.create!(itinerary_id: itinerary2.id, point_of_interest_id: poi_eiffel.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary2.id, point_of_interest_id: poi_invalides.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary2.id, point_of_interest_id: poi_saintpaul.id)

# Itinerary 3 : Marais Food & Gardens
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_cirque.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_temple.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_breizh.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_rosiers.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_hanoi.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_enfantsrouges.id)
ItineraryPointOfInterest.create!(itinerary_id: itinerary3.id, point_of_interest_id: poi_glaces.id)
puts 'Itinerary - POI joints created'
