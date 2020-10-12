class CreateServerJobStatusType < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TYPE server_job_status AS ENUM ('pending', 'running', 'finished', 'failed');
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE server_job_status;
    SQL
  end
end
