class CreateOrthogroups < ActiveRecord::Migration[5.2]
  def change
    create_table :orthogroups do |t|
      t.string :identifier

      t.timestamps
    end
  end
end
