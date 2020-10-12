class AddUserReferenceToPlantImages < ActiveRecord::Migration[5.2]
  def change
    add_reference :plant_images, :user, index: true
  end
end
