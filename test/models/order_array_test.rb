require 'test_helper'

class OrderArrayTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = customers(:customer_one).order_arrays.build
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    o = customers(:customer_one).order_arrays.build(name: 'plop', base_date: Date.new, length: 7)
    assert o.save
  end

  test 'should compute length' do
    o = order_arrays(:order_array_one)

    o.base_date = Date.new(2000,2,1)
    o.length = 31
    assert o.days, 31

    o.base_date = Date.new(2000,1,1)
    assert o.days, 28

    assert o.days, 7
    o.length = 7
  end

  test 'should duplicate' do
    o = order_arrays(:order_array_one)
    assert 2, o.orders[0].products.size

    oo = o.amoeba_dup
    assert 2, oo.orders[0].products.size
  end

  test 'should add destination' do
    o = order_arrays(:order_array_one)
    s = o.orders.size

    o.add_visit(visits(:visit_two))
    assert_equal s + o.days, o.orders.size
  end
end
