class CleanTableDestinationsTags < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute('DELETE FROM destinations_tags USING destinations,tags WHERE destinations.id=destinations_tags.destination_id AND tags.id=destinations_tags.tag_id AND destinations.customer_id!=tags.customer_id;')
  end
end
