class CreateParasiticRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :parasitic_relationships do |t|
      t.references :parasite, index: true, foreign_key: { to_table: :taxons, on_delete: :cascade}
      t.references :host, index: true, foreign_key: { to_table: :taxons, on_delete: :cascade}

      t.timestamps
    end
  end
end
