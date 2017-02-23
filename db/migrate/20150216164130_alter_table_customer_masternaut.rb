class AlterTableCustomerMasternaut < ActiveRecord::Migration
  def up
    remove_column :customers, :masternaut_account
  end

  def down
    add_column :customers, :masternaut_account, :string
  end
end
