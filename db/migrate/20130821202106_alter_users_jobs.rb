class AlterUsersJobs < ActiveRecord::Migration
  def change
    add_column :users, :job_geocoding_id, :integer
    add_column :users, :job_optimizer_id, :integer
  end
end
