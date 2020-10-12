class ChangeColumnsOfPlantImages < ActiveRecord::Migration[5.2]
  def up
    remove_column :plant_images, :photographers
    remove_column :plant_images, :creation_date

    add_column :plant_images, :attribution, :string
    add_column :plant_images, :observed_on, :date
  end

  def down
    remove_column :plant_images, :attribution
    remove_column :plant_images, :observed_on

    add_column :plant_images, :photographers, :text, array: true, default: []
    add_column :plant_images, :creation_date, :date
  end
end
