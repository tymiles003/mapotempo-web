class AlterRoutesHiddenLockedTime < ActiveRecord::Migration
  def change
    add_column :routes, :start, :time
    add_column :routes, :end, :time
    add_column :routes, :hidden, :boolean
    add_column :routes, :locked, :boolean
  end
end
