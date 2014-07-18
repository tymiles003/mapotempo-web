class AlterTablePlanningZoningOutOfDate < ActiveRecord::Migration
  def up
    add_column :plannings, :zoning_out_of_date, :boolean
    Planning.find_each{ |planning|
      planning.zoning_out_of_date = planning.zoning && planning.updated_at < planning.zoning.updated_at
      planning.save!
    }
  end

  def down
    remove_column :plannings, :zoning_out_of_date
  end
end
