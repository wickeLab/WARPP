class RemoveJsonColumnFromSubmissions < ActiveRecord::Migration[5.2]
  def up
    remove_column :submissions, :submitted_info
  end

  def down
    add_column :submissions, :submitted_info, :json
  end
end
