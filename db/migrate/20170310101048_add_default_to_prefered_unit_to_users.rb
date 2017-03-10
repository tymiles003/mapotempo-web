class AddDefaultToPreferedUnitToUsers < ActiveRecord::Migration
  def up
    change_column :users, :prefered_unit, :string, default: 'km'

    User.order(:id).each do |user|
      if user.prefered_unit.nil?
        user.prefered_unit = 'km'
        user.save!
      end
    end
  end

  def down
    change_column :users, :prefered_unit, :string
  end
end
