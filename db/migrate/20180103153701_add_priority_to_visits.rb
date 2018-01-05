class AddPriorityToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :priority, :integer
  end
end
