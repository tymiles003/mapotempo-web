class AlterPlanningZoning < ActiveRecord::Migration
  def change
    add_column :plannings, :zoning_id, :integer
  end
end
