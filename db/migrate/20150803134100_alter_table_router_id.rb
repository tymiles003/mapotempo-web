class AlterTableRouterId < ActiveRecord::Migration
  def up
    add_column :routers, :ref, :string
  end

  def down
    remove_column :routers, :ref
  end
end
