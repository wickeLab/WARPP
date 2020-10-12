class AddIndexToPublicationAuthors < ActiveRecord::Migration[5.2]
  def change
    add_index :publications, :authors, using: 'gin'
  end
end
