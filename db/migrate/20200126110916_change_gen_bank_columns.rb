class ChangeGenBankColumns < ActiveRecord::Migration[5.2]
  def up
    remove_column :gen_banks, :transcriptome_est

    remove_column :gen_banks, :est
    remove_column :gen_banks, :mtdna
    remove_column :gen_banks, :others
    remove_column :gen_banks, :plastome
    remove_column :gen_banks, :sra
    remove_column :gen_banks, :whole_genome

    add_column :gen_banks, :est, :integer
    add_column :gen_banks, :mtdna, :integer
    add_column :gen_banks, :others, :integer
    add_column :gen_banks, :plastome, :integer
    add_column :gen_banks, :sra, :integer
    add_column :gen_banks, :whole_genome, :integer
  end

  def down
    remove_column :gen_banks, :est
    remove_column :gen_banks, :mtdna
    remove_column :gen_banks, :others
    remove_column :gen_banks, :plastome
    remove_column :gen_banks, :sra
    remove_column :gen_banks, :whole_genome

    add_column :gen_banks, :transcriptome_est, :string

    add_column :gen_banks, :est, :string
    add_column :gen_banks, :mtdna, :string
    add_column :gen_banks, :others, :string
    add_column :gen_banks, :plastome, :string
    add_column :gen_banks, :sra, :string
    add_column :gen_banks, :whole_genome, :string
  end
end
