class AddBelongsToPlantImage < ActiveRecord::Migration[5.2]
  def change
    add_reference :plant_images, :taxonomic_level
  end
end
