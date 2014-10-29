class AlterTableDelayedJobsProgress < ActiveRecord::Migration
  def up
    change_column :delayed_jobs, :progress, :string
  end

  def down
    change_column :delayed_jobs, :progress, :integer
  end
end
