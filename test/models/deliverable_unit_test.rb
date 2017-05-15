require 'test_helper'

class DeliverableUnitTest < ActiveSupport::TestCase
  test 'should not save' do
    customer = customers(:customer_one).deliverable_units.build(optimization_overload_multiplier: -2)
    assert_not customer.save, 'Saved with bad fields'
  end

  test 'should not save with invalid ref' do
    customer = customers(:customer_one).deliverable_units.build(ref: 'test.test')
    assert_not customer.save, 'Saved with bad ref fields'
  end

  test 'should save' do
    customer = customers(:customer_one).deliverable_units.build(label: 'plop')
    assert customer.save
  end

  test 'should save with localized attributes' do
    customer = customers(:customer_one).deliverable_units.build(default_quantity: '1,0', default_capacity: '10,0', optimization_overload_multiplier: '0,1')
    assert customer.save
    assert_equal 1, customer.default_quantity
  end
end
