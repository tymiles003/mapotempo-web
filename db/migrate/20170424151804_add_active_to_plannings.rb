class AddActiveToPlannings < ActiveRecord::Migration
  def up
    add_column :plannings, :active, :boolean, default: true

    Planning.transaction do
      Planning.find_in_batches do |plannings|
        plannings.each do |planning|
          planning.active = true
          planning.save!
        end
      end
    end
  end

  def down
    remove_column :plannings, :active
  end
end
