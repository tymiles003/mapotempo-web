require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @customer = customers(:customer_one)
  end

  test "should not save" do
    o = Customer.new
    assert_not o.save, "Saved without required fields"
  end

  test "should stop job matrix" do
    assert_difference('Delayed::Backend::ActiveRecord::Job.count', -1) do
      @customer.job_matrix.destroy
    end
  end
end
