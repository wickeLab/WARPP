class AddRequestTypeToSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :request_type, :string
  end
end
