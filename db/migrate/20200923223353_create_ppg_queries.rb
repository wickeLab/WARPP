class CreatePpgQueries < ActiveRecord::Migration[5.2]
  def change
    create_table :ppg_queries do |t|
      t.string :query_name, null: false, index: true, unique: true
      t.string :functional_assignment, null: false, default: 'unknown', index: true
      t.float :median_functionality_score, index: true

      t.references :taxon, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
