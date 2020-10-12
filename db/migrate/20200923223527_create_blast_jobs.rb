class CreateBlastJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :blast_jobs do |t|
      t.column :status, :server_job_status, default: 'pending', index: true
      t.string :title
      t.numeric :evalue
      t.integer :word_size
      t.integer :max_target_seqs
      t.string :database

      t.boolean :email_notification, default: false

      t.timestamps
    end
  end
end
