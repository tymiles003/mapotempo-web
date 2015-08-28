class AlterStoresRemoveOpenClose < ActiveRecord::Migration
  def up
    remove_column :stores, :open
    remove_column :stores, :close
  end

  def down
    add_column :stores, :open, :time
    add_column :stores, :close, :time
  end
end
