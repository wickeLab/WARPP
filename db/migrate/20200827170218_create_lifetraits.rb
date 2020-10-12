class CreateLifetraits < ActiveRecord::Migration[5.2]
  def change
    create_table :lifetraits do |t|
      t.references :taxon, index: true, foreign_key: { on_delete: :cascade }
      t.text :information, null: false
      t.string :type, null: false

      t.timestamps
    end
  end
end
