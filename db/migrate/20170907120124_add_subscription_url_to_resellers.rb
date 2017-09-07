class AddSubscriptionUrlToResellers < ActiveRecord::Migration
  def change
    add_column :resellers, :subscription_url, :string
  end
end
