class AddOrthogroupReferences < ActiveRecord::Migration[5.2]
  def change
    add_reference :trees, :orthogroup, foreign_key: true
  end
end
