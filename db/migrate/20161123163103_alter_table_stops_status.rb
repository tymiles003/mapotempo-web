class AlterTableStopsStatus < ActiveRecord::Migration
  def change
    add_column :stops, :status, :string
    add_column :stops, :eta, :datetime
  end
end
