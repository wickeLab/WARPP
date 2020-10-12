class AddStatusToSubmissions < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TYPE submission_status AS ENUM ('pending', 'accepted', 'rejected');
    SQL
    add_column :submissions, :status, :submission_status
    add_index :submissions, :status
  end

  def down
    remove_column :submissions, :status
    execute <<-SQL
      DROP TYPE submission_status;
    SQL
  end
end
