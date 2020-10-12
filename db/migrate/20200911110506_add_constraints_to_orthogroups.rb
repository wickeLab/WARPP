class AddConstraintsToOrthogroups < ActiveRecord::Migration[5.2]
  def change
    add_index :orthogroups, :identifier, unique: true
    change_column_null :orthogroups, :identifier, false
  end
end
