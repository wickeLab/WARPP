class CreatePpgMatches < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TYPE ppg_stringency AS ENUM ('stringent', 'relaxed');
    SQL

    create_table :ppg_matches do |t|
      t.string :target, null: false, index: true
      t.numeric :functionality_score, null: false
      t.column :stringency, :ppg_stringency, null: false, default: 'stringent', index: true

      t.references :ppg_job, foreign_key: { on_delete: :cascade }
      t.references :ppg_query, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end

  def down
    drop_table :ppg_matches
    execute <<-SQL
      DROP TYPE ppg_stringency;
    SQL
  end
end
