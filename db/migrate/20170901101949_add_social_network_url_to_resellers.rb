class AddSocialNetworkUrlToResellers < ActiveRecord::Migration
  def change
    add_column :resellers, :facebook_url, :string
    add_column :resellers, :twitter_url, :string
    add_column :resellers, :linkedin_url, :string
  end
end
