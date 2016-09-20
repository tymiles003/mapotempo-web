require 'test_helper'

class DeliverableUnitTest < ActiveSupport::TestCase

  test 'should not save' do
    o = customers(:customer_one).deliverable_units.build(optimization_overload_multiplier: -1)
    assert_not o.save, 'Saved with bad fields'
  end

  test 'should save' do
    o = customers(:customer_one).deliverable_units.build(label: 'plop')
    assert o.save
  end

  test 'should save with localized attributes' do
    o = customers(:customer_one).deliverable_units.build(default_quantity: '1,0', default_capacity: '10,0', optimization_overload_multiplier: '0,1')
    assert o.save
    assert_equal 1, o.default_quantity
  end
end
