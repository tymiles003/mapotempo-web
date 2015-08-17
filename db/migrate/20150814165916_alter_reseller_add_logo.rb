class AlterResellerAddLogo < ActiveRecord::Migration
  def up
    add_column :resellers, :logo_large, :string
    add_column :resellers, :logo_small, :string
    add_column :resellers, :favicon, :string
  end

  def down
    remove_column :resellers, :logo_large
    remove_column :resellers, :logo_small
    remove_column :resellers, :favicon
  end
end
