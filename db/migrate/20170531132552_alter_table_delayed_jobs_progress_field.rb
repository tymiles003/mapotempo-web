class AlterTableDelayedJobsProgressField < ActiveRecord::Migration
  def up
    change_column_null :delayed_jobs, :progress, true
    change_column_default :delayed_jobs, :progress, nil
  end

  def down
    change_column_default :delayed_jobs, :progress, '0'
    change_column_null :delayed_jobs, :progress, false
  end
end
