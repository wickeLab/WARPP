class CreateTaxons < ActiveRecord::Migration[5.2]
  def change
    create_table :taxons do |t|
      t.string :ancestry, index: true
      t.integer :ancestry_depth, default: 0

      t.citext :scientific_name, null: false
      t.index :scientific_name, unique: true

      t.string :authorship

      t.float :information_score, default: 0.0
      t.float :reliability_score, default: 0.0

      t.timestamps
    end
  end
end
