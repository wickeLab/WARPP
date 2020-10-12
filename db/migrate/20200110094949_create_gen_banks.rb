class CreateGenBanks < ActiveRecord::Migration[5.2]
  def change
    create_table :gen_banks do |t|
      t.string :est
      t.string :plastome
      t.string :mtdna
      t.string :whole_genome
      t.string :transcriptome_est
      t.string :sra
      t.string :others
      t.timestamps
    end
  end
end
