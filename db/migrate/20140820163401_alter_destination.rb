class AlterDestination < ActiveRecord::Migration
  def up
    add_column :destinations, :take_over, :time
  end

  def down
    remove_column :destination, :take_over
  end
end
