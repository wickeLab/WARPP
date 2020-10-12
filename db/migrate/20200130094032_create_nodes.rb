class CreateNodes < ActiveRecord::Migration[5.2]
  def change
    create_table :nodes do |t|

      t.timestamps
      t.column :ancestry, :string, index: true
      t.column :ancestry_depth, :integer, default: 0

      t.column :probability_lifespan, :float
      t.column :probability_habit, :float
      t.column :probability_holo, :float
      t.column :probability_obligate, :float
    end
  end
end
