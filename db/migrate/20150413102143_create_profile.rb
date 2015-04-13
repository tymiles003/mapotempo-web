class CreateProfile < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.string :name
    end

    create_table :layers_profiles, id: false do |t|
      t.integer :profile_id
      t.integer :layer_id
    end

    create_table :profiles_routers, id: false do |t|
      t.integer :profile_id
      t.integer :router_id
    end

    profile = Profile.create!(name: 'Default', layers: Layer.all, routers: Router.all)

    add_column :customers, :profile_id, :integer
    change_column :customers, :router_id, :integer, null: false

    Customer.all.each { |customer|
      customer.profile = profile
      customer.save!
    }

    change_column :customers, :profile_id, :integer, null: false
    add_foreign_key :customers, :profiles
  end
end
