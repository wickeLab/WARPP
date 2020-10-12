class ChangeLicenseColumnOfPlantImages < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TYPE license_types AS ENUM ('none', 'CC-BY', 'CC-BY-NC', 'CC-BY-SA', 'CC-BY-ND', 'CC-BY-NC-SA', 'CC-BY-NC-ND');
    SQL
    add_column :plant_images, :license, :license_types
  end

  def down
    remove_column :plant_images, :license
    execute <<-SQL
      DROP TYPE license_types;
    SQL
  end
end
