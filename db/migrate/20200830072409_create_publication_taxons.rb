class CreatePublicationTaxons < ActiveRecord::Migration[5.2]
  def change
    create_table :publication_taxons do |t|
      t.references :publication, foreign_key: { on_delete: :cascade }
      t.references :taxon, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
