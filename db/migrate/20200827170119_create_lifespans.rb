class CreateLifespans < ActiveRecord::Migration[5.2]
  def change
    create_table :lifespans do |t|

      t.timestamps
    end
  end
end
