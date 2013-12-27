class AlterCustomerTakeOver < ActiveRecord::Migration
  def down
    change_column :customers, :take_over, :integer
  end

  def up
    change_column :customers, :take_over, :time
  end
end
