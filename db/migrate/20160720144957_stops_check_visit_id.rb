class StopsCheckVisitId < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute "ALTER TABLE stops ADD CONSTRAINT check_visit_id CHECK (type != 'StopVisit' OR visit_id IS NOT NULL);"
  end
  def self.down
    ActiveRecord::Base.connection.execute "ALTER TABLE stops DROP CONSTRAINT check_visit_id;"
  end
end
