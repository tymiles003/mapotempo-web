class AlterDatabaseTransactionIsolationLevel < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute('ALTER DATABASE "' + ActiveRecord::Base.connection_config[:database] + '" SET default_transaction_isolation TO \'REPEATABLE READ\';')
  end
  def down
    ActiveRecord::Base.connection.execute('ALTER DATABASE "' + ActiveRecord::Base.connection_config[:database] + '" SET default_transaction_isolation TO \'READ COMMITED\';')
  end
end
