class MakeBlastEvalueAcceptString < ActiveRecord::Migration[5.2]
  def up
    remove_column :blast_jobs, :evalue
    add_column :blast_jobs, :evalue, :string
  end

  def down
    remove_column :blast_jobs, :evalue
    add_column :blast_jobs, :evalue, :numeric
  end
end
