class CreateOrthogroupTaxons < ActiveRecord::Migration[5.2]
  def change
    create_table :orthogroup_taxons do |t|
      t.references :taxon, foreign_key: { on_delete: :cascade }
      t.references :orthogroup, foreign_key: { on_delete: :cascade }
      t.column :entries, :text, array: true, default: []
      t.column :identifier, :text, null: false

      t.index %i[identifier orthogroup_id], unique: true

      t.column :identifier, :text, index: true, null: false

      t.timestamps
    end
  end
end
