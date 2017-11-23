class AlterTableVisitQuantitiesOperation < ActiveRecord::Migration
  def change
    add_column :visits, :quantities_operations, :hstore
  end
end
