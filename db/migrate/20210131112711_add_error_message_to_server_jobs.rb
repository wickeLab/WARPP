class AddErrorMessageToServerJobs < ActiveRecord::Migration[6.1]
  def change
    add_column :blast_jobs, :error_message, :text
    add_column :ppg_jobs, :error_message, :text
  end
end
