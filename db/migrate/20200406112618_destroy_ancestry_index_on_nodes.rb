class DestroyAncestryIndexOnNodes < ActiveRecord::Migration[5.2]
  def change
    remove_index :nodes, :ancestry
  end
end
