class CreateGenomeSizes < ActiveRecord::Migration[5.2]
  def change
    create_table :genome_sizes do |t|

      t.timestamps
    end
  end
end
