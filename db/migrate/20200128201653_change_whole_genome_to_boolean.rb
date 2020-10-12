class ChangeWholeGenomeToBoolean < ActiveRecord::Migration[5.2]
  def up
    remove_column :gen_banks, :whole_genome
    add_column :gen_banks, :whole_genome, :boolean
  end

  def down
    remove_column :gen_banks, :whole_genome
    add_column :gen_banks, :whole_genome, :integer
  end
end
