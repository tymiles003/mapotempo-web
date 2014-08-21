class AlterCustomer < ActiveRecord::Migration
  def up
    add_column :customers, :print_planning_annotating, :boolean
  end

  def down
    remove_column :customers, :print_planning_annotating
  end
end
