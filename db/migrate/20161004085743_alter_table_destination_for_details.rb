class AlterTableDestinationForDetails < ActiveRecord::Migration
  def change
    change_column :destinations, :detail, :text
  end
end
