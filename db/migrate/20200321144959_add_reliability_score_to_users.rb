class AddReliabilityScoreToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :reliablity_score, :float
  end
end
