class AddYearToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :year, :integer
  end
end
