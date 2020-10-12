class CreatePpgJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :ppg_jobs do |t|
      t.column :status, :server_job_status, default: 'pending', index: true
      t.string :title

      t.integer :maxintron
      t.integer :minintron
      t.text :stringency, array: true, default: []
      t.float :stringency_value
      t.integer :best_hits
      t.string :mode

      t.boolean :out_identity, default: false
      t.boolean :out_frame_shifts, default: false
      t.boolean :out_missing_genes, default: false
      t.boolean :out_sequences, default: false
      t.boolean :out_annotation, default: false
      t.boolean :email_notification, default: false

      t.timestamps
    end
  end
end
