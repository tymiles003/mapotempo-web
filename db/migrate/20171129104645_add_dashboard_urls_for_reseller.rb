class AddDashboardUrlsForReseller < ActiveRecord::Migration
  def change
    add_column :resellers, :audience_url, :string
    add_column :resellers, :behavior_url, :string

    add_column :resellers, :customer_audience_url, :string
    add_column :resellers, :customer_behavior_url, :string
  end
end
