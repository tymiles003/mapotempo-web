class ChangeTimeToIntegerToCustomers < ActiveRecord::Migration
  def up
    fake_missing_props

    add_column :customers, :take_over_temp, :integer

    Customer.connection.schema_cache.clear!
    Customer.reset_column_information

    Customer.transaction do
      Customer.find_in_batches do |customers|
        customers.each do |customer|
          customer.take_over_temp = customer.take_over.seconds_since_midnight.to_i if customer.take_over
          customer.save!
        end
      end
    end

    remove_column :customers, :take_over

    rename_column :customers, :take_over_temp, :take_over
  end

  def down
    add_column :customers, :take_over_temp, :time

    Customer.connection.schema_cache.clear!
    Customer.reset_column_information

    Customer.transaction do
      Customer.find_in_batches do |customers|
        customers.each do |customer|
          customer.take_over_temp = Time.at(customer.take_over).utc.strftime('%H:%M:%S') if customer.take_over
          customer.save!
        end
      end
    end

    fake_missing_props

    remove_column :customers, :take_over

    rename_column :customers, :take_over_temp, :take_over
  end

  def fake_missing_props
    Customer.class_eval do
      attribute :take_over, ActiveRecord::Type::Time.new

      skip_callback :update, :before, :update_out_of_date, :update_max_vehicles, :update_enable_multi_visits
      skip_callback :save, :before, :sanitize_print_header, :nilify_router_options_blanks
      skip_callback :save, :before, :devices_update_vehicles
    end
  end
end
