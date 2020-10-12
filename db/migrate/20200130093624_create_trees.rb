class CreateTrees < ActiveRecord::Migration[5.2]
  def change
    create_table :trees do |t|

      t.timestamps
      t.column :published_at, :date
      t.column :basis, :integer
    end
  end
end
