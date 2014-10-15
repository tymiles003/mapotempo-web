class AlterStopWaitTime < ActiveRecord::Migration
  def up
    add_column :stops, :wait_time, :integer
  end

  def down
    remove_column :stops, :wait_time
  end
end
