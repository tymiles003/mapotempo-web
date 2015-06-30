class AlterTableDestinationComment < ActiveRecord::Migration
  def up
    change_column :destinations, :comment, :text
  end

  def down
    change_column :destinations, :comment, :string
  end
end
