class AddLocaleToRouters < ActiveRecord::Migration
  def change
    add_column :routers, :name_locale, :hstore, default: {}, null: false
  end
end
