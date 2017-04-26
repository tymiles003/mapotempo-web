class AddActiveToPlannings < ActiveRecord::Migration
  def change
    add_column :plannings, :active, :boolean, default: false
  end
end
