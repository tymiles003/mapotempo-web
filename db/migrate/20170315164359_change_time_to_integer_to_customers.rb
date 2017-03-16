class ChangeTimeToIntegerToCustomers < ActiveRecord::Migration
  def up
    previous_times = {}
    Customer.all.order(:id).each do |customer|
      previous_times[customer.id] = {
          take_over: customer.take_over
      }
    end

    remove_column :customers, :take_over
    add_column :customers, :take_over, :integer

    Customer.reset_column_information
    Customer.transaction do
      previous_times.each do |customer_id, times|
        customer = Customer.find(customer_id)
        customer.take_over = times[:take_over].seconds_since_midnight.to_i if times[:take_over]
        customer.save!
      end
    end
  end

  def down
    previous_times = {}
    Customer.all.order(:id).each do |customer|
      previous_times[customer.id] = {
          take_over: customer.take_over
      }
    end

    remove_column :customers, :take_over
    add_column :customers, :take_over, :time

    Customer.reset_column_information
    Customer.transaction do
      previous_times.each do |customer_id, times|
        customer = Customer.find(customer_id)
        customer.take_over = Time.at(times[:take_over]).utc.strftime('%H:%M:%S') if times[:take_over]
        customer.save!
      end
    end
  end
end
