class AddJsonbSubmittedInformationToSubmissions < ActiveRecord::Migration[5.2]
  def up
    rename_column :submissions, :submitted_information, :submitted_info
    add_column :submissions, :submitted_information, :jsonb, null: false, default: '{}'
    add_index :submissions, :submitted_information, using: :gin
  end

  def down
    remove_index :submissions, :submitted_information
    remove_column :submissions, :submitted_information
    rename_column :submissions, :submitted_info, :submitted_information
  end
end
