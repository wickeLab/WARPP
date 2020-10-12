class DeleteProbabilityColumnsFromNode < ActiveRecord::Migration[5.2]
  def up
    remove_column :nodes, :probability_habit
    remove_column :nodes, :probability_obligate
    remove_column :nodes, :probability_holo
    remove_column :nodes, :probability_lifespan

    add_column :nodes, :probability_lifespan, :float, array: true, default: []
    add_column :nodes, :probability_lifestyle, :float, array: true, default: []
  end

  def down
    remove_column :nodes, :probability_lifespan
    remove_column :nodes, :probability_lifestyle

    add_column :nodes, :probability_habit, :float
    add_column :nodes, :probability_obligate, :float
    add_column :nodes, :probability_holo, :float
    add_column :nodes, :probability_lifespan, :float
  end
end
