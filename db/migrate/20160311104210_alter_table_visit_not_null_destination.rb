class AlterTableVisitNotNullDestination < ActiveRecord::Migration
  def up
    change_column :visits, :destination_id, :integer, null: false
  end
  def down
    change_column :visits, :destination_id, :integer, null: true
  end
end
