class AlterCustomerAlyacom < ActiveRecord::Migration
  def up
    add_column :customers, :alyacom_association, :string
  end

  def down
    remove_column :customers, :alyacom_association
  end
end
