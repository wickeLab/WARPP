class AddDoiToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :doi, :string
  end
end
