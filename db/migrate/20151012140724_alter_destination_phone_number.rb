class AlterDestinationPhoneNumber < ActiveRecord::Migration
  def up
    add_column :destinations, :phone_number, :string
  end

  def down
    remove_column :destinations, :phone_number
  end
end
