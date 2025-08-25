class CreateItineraries < ActiveRecord::Migration[7.1]
  def change
    create_table :itineraries do |t|
      t.integer :duration
      t.string :theme
      t.references :itinerary_objective, null: false, foreign_key: true

      t.timestamps
    end
  end
end
