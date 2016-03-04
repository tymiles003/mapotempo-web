class AddRouteLastSentAt < ActiveRecord::Migration
  def change
    add_column :routes, :last_sent_at, :datetime
  end
end
