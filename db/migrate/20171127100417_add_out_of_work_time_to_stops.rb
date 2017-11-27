class AddOutOfWorkTimeToStops < ActiveRecord::Migration
  def change
    add_column :stops, :out_of_work_time, :boolean
  end
end
