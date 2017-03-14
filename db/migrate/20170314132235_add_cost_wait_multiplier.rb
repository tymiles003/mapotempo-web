class AddCostWaitMultiplier < ActiveRecord::Migration
  def change
    add_column :customers, :cost_waiting_time, :float
  end
end
