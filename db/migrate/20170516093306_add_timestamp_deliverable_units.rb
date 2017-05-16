class AddTimestampDeliverableUnits < ActiveRecord::Migration
  def change
    add_column :deliverable_units, :created_at, :datetime
    add_column :deliverable_units, :updated_at, :datetime
  end
end
