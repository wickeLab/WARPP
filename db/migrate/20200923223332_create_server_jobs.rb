class CreateServerJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :server_jobs do |t|
      t.references :user, foreign_key: { on_delete: :cascade }
      t.references :job, polymorphic: true

      t.timestamps
    end
  end
end
