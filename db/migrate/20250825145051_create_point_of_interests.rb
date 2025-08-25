class CreatePointOfInterests < ActiveRecord::Migration[7.1]
  def change
    create_table :point_of_interests do |t|
      t.string :name
      t.string :description
      t.string :category
      t.references :address, null: false, foreign_key: true

      t.timestamps
    end
  end
end
