class ChangeTimeToIntegerToVisits < ActiveRecord::Migration
  def up
    fake_missing_props

    add_column :visits, :open1_temp, :integer
    add_column :visits, :close1_temp, :integer
    add_column :visits, :take_over_temp, :integer
    add_column :visits, :open2_temp, :integer
    add_column :visits, :close2_temp, :integer

    Visit.connection.schema_cache.clear!
    Visit.reset_column_information

    Visit.transaction do
      Visit.find_in_batches do |visits|
        visits.each do |visit|
          visit.open1_temp = visit.open1.seconds_since_midnight.to_i if visit.open1
          visit.close1_temp = visit.close1.seconds_since_midnight.to_i if visit.close1
          visit.take_over_temp = visit.take_over.seconds_since_midnight.to_i if visit.take_over
          visit.open2_temp = visit.open2.seconds_since_midnight.to_i if visit.open2
          visit.close2_temp = visit.close2.seconds_since_midnight.to_i if visit.close2
          visit.save!(validate: false)
        end
      end
    end

    remove_column :visits, :open1
    remove_column :visits, :close1
    remove_column :visits, :take_over
    remove_column :visits, :open2
    remove_column :visits, :close2

    rename_column :visits, :open1_temp, :open1
    rename_column :visits, :close1_temp, :close1
    rename_column :visits, :take_over_temp, :take_over
    rename_column :visits, :open2_temp, :open2
    rename_column :visits, :close2_temp, :close2
  end

  def down
    add_column :visits, :open1_temp, :time
    add_column :visits, :close1_temp, :time
    add_column :visits, :take_over_temp, :time
    add_column :visits, :open2_temp, :time
    add_column :visits, :close2_temp, :time

    Visit.connection.schema_cache.clear!
    Visit.reset_column_information

    Visit.transaction do
      Visit.find_in_batches do |visits|
        visits.each do |visit|
          visit.open1_temp = Time.at(visit.open1).utc.strftime('%H:%M:%S') if visit.open1
          visit.close1_temp = Time.at(visit.close1).utc.strftime('%H:%M:%S') if visit.close1
          visit.take_over_temp = Time.at(visit.take_over).utc.strftime('%H:%M:%S') if visit.take_over
          visit.open2_temp = Time.at(visit.open2).utc.strftime('%H:%M:%S') if visit.open2
          visit.close2_temp = Time.at(visit.close2).utc.strftime('%H:%M:%S') if visit.close2
          visit.save!
        end
      end
    end

    remove_column :visits, :open1
    remove_column :visits, :close1
    remove_column :visits, :take_over
    remove_column :visits, :open2
    remove_column :visits, :close2

    rename_column :visits, :open1_temp, :open1
    rename_column :visits, :close1_temp, :close1
    rename_column :visits, :take_over_temp, :take_over
    rename_column :visits, :open2_temp, :open2
    rename_column :visits, :close2_temp, :close2
  end

  def fake_missing_props
    Visit.class_eval do
      attribute :open1, ActiveRecord::Type::Time.new
      attribute :close1, ActiveRecord::Type::Time.new
      attribute :open2, ActiveRecord::Type::Time.new
      attribute :close2, ActiveRecord::Type::Time.new
      attribute :take_over, ActiveRecord::Type::Time.new

      skip_callback :save, :before, :update_tags, :create_orders
      skip_callback :update, :before, :update_out_of_date
    end
  end
end
