class CreateChromosomeNumbers < ActiveRecord::Migration[5.2]
  def change
    create_table :chromosome_numbers do |t|

      t.timestamps
    end
  end
end
