require 'test_helper'

class DeliverableUnitTest < ActiveSupport::TestCase
  test 'should not save' do
    unit = customers(:customer_one).deliverable_units.build(optimization_overload_multiplier: -2)
    assert_not unit.save, 'Saved with bad fields'
  end

  test 'should not save with invalid ref' do
    unit = customers(:customer_one).deliverable_units.build(ref: 'test.test')
    assert_not unit.save, 'Saved with bad ref fields'
  end

  test 'should create' do
    unit = customers(:customer_one).deliverable_units.build(label: 'plop', default_quantity: '')
    assert unit.save
    assert_nil unit.default_quantity
    assert_nil unit.localized_default_quantity
  end

  test 'should update' do
    unit = deliverable_units(:deliverable_unit_one_one)
    unit.default_capacity = ''
    assert unit.save
    assert_nil unit.default_capacity
    assert_nil unit.localized_default_capacity
  end

  test 'should save with localized attributes' do
    unit = customers(:customer_one).deliverable_units.build(default_quantity: '1,0', default_capacity: '10,0', optimization_overload_multiplier: '0,1')
    assert unit.save
    assert_equal 1, unit.default_quantity
  end
end
