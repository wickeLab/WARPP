class AllowNullValuesAsFunctionalityScore < ActiveRecord::Migration[5.2]
  def up
    change_column_null :ppg_matches, :functionality_score, true
  end

  def down
    change_column_null :ppg_matches, :functionality_score, false
  end
end
