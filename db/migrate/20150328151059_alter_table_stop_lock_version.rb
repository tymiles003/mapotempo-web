class AlterTableStopLockVersion < ActiveRecord::Migration
  def up
    add_column :stops, :lock_version, :integer, default: 0, null: false
  end

  def down
    remove_column :stops, :lock_version
  end
end
