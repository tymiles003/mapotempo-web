class AlterTableRoutesDropBuildAt < ActiveRecord::Migration
  def up
    remove_column :routes, :build_at
  end
end
