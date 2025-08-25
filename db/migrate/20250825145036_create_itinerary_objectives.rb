class CreateItineraryObjectives < ActiveRecord::Migration[7.1]
  def change
    create_table :itinerary_objectives do |t|
      t.string :name
      t.references :departure_address, null: false, foreign_key: { to_table: :addresses }
      t.references :arrival_address, null: false, foreign_key: { to_table: :addresses }
      t.integer :duration_objective
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
