class AddIconForDeliverableUnits < ActiveRecord::Migration
  def change
    add_column :deliverable_units, :icon, :string
  end
end
