class AlterStopsTrace < ActiveRecord::Migration
  def down
    change_column :stops, :trace, :string
  end

  def up
    change_column :stops, :trace, :text
  end
end
