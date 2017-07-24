class AlterTableDelayedJobsProgressField < ActiveRecord::Migration
  def up
    change_column_null :delayed_jobs, :progress, true
    change_column_default :delayed_jobs, :progress, nil

    Delayed::Backend::ActiveRecord::Job.all.each do |delayed_job|
      delayed_job.progress = nil if delayed_job.progress == '0'
      delayed_job.save!
    end
  end

  def down
    change_column_default :delayed_jobs, :progress, '0'

    Delayed::Backend::ActiveRecord::Job.all.each do |delayed_job|
      delayed_job.progress = '0' unless delayed_job.progress
      delayed_job.save!
    end

    change_column_null :delayed_jobs, :progress, false
  end
end
