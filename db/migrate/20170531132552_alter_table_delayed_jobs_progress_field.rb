class AlterTableDelayedJobsProgressField < ActiveRecord::Migration
  def up
    change_column_default :delayed_jobs, :progress, nil
  end

  def down
    change_column_default :delayed_jobs, :progress, '0'
  end
end
