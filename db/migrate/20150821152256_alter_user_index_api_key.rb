class AlterUserIndexApiKey < ActiveRecord::Migration
  def up
    add_index :users, :api_key, :name => 'index_users_on_api_key'
  end

  def down
    remove_index :users, column: :api_key
  end
end
