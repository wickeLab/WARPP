class CreateHabits < ActiveRecord::Migration[5.2]
  def change
    create_table :habits do |t|

      t.timestamps
    end
  end
end
