class UsersSetTimeZone < ActiveRecord::Migration
  def self.up
    change_column :users, :time_zone, :string, null: false, default: 'UTC'
    User.update_all time_zone: 'Paris'
  end
  def self.down
    change_column :users, :time_zone, :string
    User.update_all time_zone: 'UTC'
  end
end
