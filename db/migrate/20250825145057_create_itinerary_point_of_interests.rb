class CreateItineraryPointOfInterests < ActiveRecord::Migration[7.1]
  def change
    create_table :itinerary_point_of_interests do |t|
      t.references :itinerary, null: false, foreign_key: true
      t.references :point_of_interest, null: false, foreign_key: true

      t.timestamps
    end
  end
end
