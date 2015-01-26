class AlterCustomerAlyacom < ActiveRecord::Migration
  def up
    add_column :customers, :alyacom_association, :string
  end

  def donw
    remove_column :customers, :alyacom_association
  end
end
