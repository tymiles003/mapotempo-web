class UpdateUsersAddToken < ActiveRecord::Migration
  # https://github.com/plataformatec/devise/wiki/How-To:-Add-:confirmable-to-Users
  def self.up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_index :users, :confirmation_token, unique: true
    execute "UPDATE users SET confirmed_at = NOW()"
    User.find_each do |user|
      user.send :generate_confirmation_token
      user.save!
    end
  end
  def self.down
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
  end
end
