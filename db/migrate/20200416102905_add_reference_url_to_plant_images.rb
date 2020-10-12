class AddReferenceUrlToPlantImages < ActiveRecord::Migration[5.2]
  def change
    add_column :plant_images, :reference_url, :string
  end
end
