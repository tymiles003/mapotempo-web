class AlterUsersTakeOverTime < ActiveRecord::Migration
  def down
    change_column :users, :take_over, :time
  end

  def up
    change_column :users, :take_over, :integer
  end
end
