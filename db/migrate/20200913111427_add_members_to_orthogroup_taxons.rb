class AddMembersToOrthogroupTaxons < ActiveRecord::Migration[5.2]
  def change
    add_column :orthogroup_taxons, :members, :jsonb, null: false, default: {}
    add_index :orthogroup_taxons, :members, using: :gin
  end
end
