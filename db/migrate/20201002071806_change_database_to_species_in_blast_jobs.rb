class ChangeDatabaseToSpeciesInBlastJobs < ActiveRecord::Migration[5.2]
  def up
    remove_column :blast_jobs, :database
    add_column :blast_jobs, :species, :string
  end

  def down
    remove_column :blast_jobs, :species
    add_column :blast_jobs, :database, :string
  end
end
