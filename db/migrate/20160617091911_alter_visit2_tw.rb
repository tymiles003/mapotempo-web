class AlterVisit2Tw < ActiveRecord::Migration
  def self.up
    rename_column :visits, :open, :open1
    rename_column :visits, :close, :close1

    add_column :visits, :open2, :time
    add_column :visits, :close2, :time
  end

  def self.down
    rename_column :visits, :open1, :open
    rename_column :visits, :close1, :close

    remove_columns :visits, :open2
    remove_columns :visits, :close2
  end
end
