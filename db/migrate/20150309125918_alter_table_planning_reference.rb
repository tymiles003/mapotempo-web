class AlterTablePlanningReference < ActiveRecord::Migration
  def up
    add_column :plannings, :ref, :string
  end

  def down
    remove_column :plannings, :ref
  end
end
