class AlterTableRoutesLastSentTo < ActiveRecord::Migration
  def change
    add_column :routes, :last_sent_to, :string
  end
end
