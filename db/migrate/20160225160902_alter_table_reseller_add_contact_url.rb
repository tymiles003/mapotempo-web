class AlterTableResellerAddContactUrl < ActiveRecord::Migration
  def up
    add_column :resellers, :contact_url, :string
  end
  def down
    remove_column :resellers, :contact_url
  end
end
