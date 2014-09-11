class AlterUserApiKey < ActiveRecord::Migration
  def up
    add_column :users, :api_key, :string

    User.find_each{ |user|
      user.api_key = SecureRandom.hex
      user.save!
    }

    change_column :users, :api_key, :string, :null => false
  end

  def down
    remove_column :users, :api_key
  end
end
