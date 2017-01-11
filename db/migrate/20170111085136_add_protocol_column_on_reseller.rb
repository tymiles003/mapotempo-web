class AddProtocolColumnOnReseller < ActiveRecord::Migration
  def change
    add_column :resellers, :url_protocol, :string, :default => 'http'
  end
end
