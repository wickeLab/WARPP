class AddReferenceToNodes < ActiveRecord::Migration[5.2]
  def change
    add_reference :nodes, :tree, foreign_key: true
  end
end
