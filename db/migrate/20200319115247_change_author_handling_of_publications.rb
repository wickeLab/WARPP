class ChangeAuthorHandlingOfPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :authors, :text, array: true, default: []
  end
end
