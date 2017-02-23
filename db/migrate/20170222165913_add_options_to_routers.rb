class AddOptionsToRouters < ActiveRecord::Migration
  def change
    add_column :routers, :options, :hstore, default: {}, null: false
  end
end
