class AlterPlantImageColumns < ActiveRecord::Migration[5.2]
  def up
    remove_column :plant_images, :image
    remove_column :plant_images, :reference

    add_column :plant_images, :location_data, :string
    add_column :plant_images, :photographers, :text, array: true, default: []
    add_column :plant_images, :creation_date, :date
  end

  def down
    remove_column :plant_images, :location_data
    remove_column :plant_images, :photographers
    remove_column :plant_images, :creation_date

    add_column :plant_images, :image, :string
    add_column :plant_images, :reference, :string
  end
end
