class CreateSubmissions < ActiveRecord::Migration[5.2]
  def change
    create_table :submissions do |t|
      t.column :species, :string
      t.column :submitted_information, :json

      t.timestamps
    end
  end
end
