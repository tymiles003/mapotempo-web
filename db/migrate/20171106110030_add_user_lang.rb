class AddUserLang < ActiveRecord::Migration
  def change
    add_column :users, :locale, :string, null: true
  end
end
