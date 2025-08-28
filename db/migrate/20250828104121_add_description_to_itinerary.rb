class AddDescriptionToItinerary < ActiveRecord::Migration[7.1]
  def change
    add_column :itineraries, :description, :text
  end
end
