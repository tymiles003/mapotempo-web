class ChangeNameOfCostWaitingTime < ActiveRecord::Migration
  def change
    rename_column :customers, :cost_waiting_time, :optimization_cost_waiting_time
  end
end
