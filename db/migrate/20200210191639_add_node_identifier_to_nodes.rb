class AddNodeIdentifierToNodes < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :node_identifier, :string
  end
end
