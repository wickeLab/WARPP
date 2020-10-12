class CreatePlantImages < ActiveRecord::Migration[5.2]
  def change
    create_table :plant_images do |t|
      t.timestamps
      t.string :reference
      t.string :image
    end
  end
end
