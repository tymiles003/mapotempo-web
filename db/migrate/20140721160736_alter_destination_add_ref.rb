class AlterDestinationAddRef < ActiveRecord::Migration
  def up
    add_column :destinations, :ref, :string
  end

  def down
    remove_column :destinations, :ref
  end
end
