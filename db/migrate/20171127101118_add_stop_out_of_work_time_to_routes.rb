class AddStopOutOfWorkTimeToRoutes < ActiveRecord::Migration
  def change
    add_column :routes, :stop_out_of_work_time, :boolean
  end
end
