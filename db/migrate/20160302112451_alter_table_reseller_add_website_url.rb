class AlterTableResellerAddWebsiteUrl < ActiveRecord::Migration
  def up
    add_column :resellers, :website_url, :string
  end
  def down
    remove_column :resellers, :website_url
  end
end
