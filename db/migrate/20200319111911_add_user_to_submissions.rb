class AddUserToSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_reference :submissions, :user, foreign_key: true
  end
end
