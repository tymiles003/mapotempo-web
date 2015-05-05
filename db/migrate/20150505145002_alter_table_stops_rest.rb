class AlterTableStopsRest < ActiveRecord::Migration
  def up
    change_column :stops, :destination_id, :integer, null: true
    add_column :stops, :type, :string, default: 'StopDestination', null: false
  end

  def down
    change_column :stops, :destination_id, :integer, null: false
    rm_column :stops, :type
  end
end
