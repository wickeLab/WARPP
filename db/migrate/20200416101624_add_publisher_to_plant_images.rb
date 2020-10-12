class AddPublisherToPlantImages < ActiveRecord::Migration[5.2]
  def change
    add_column :plant_images, :publisher, :string
  end
end
