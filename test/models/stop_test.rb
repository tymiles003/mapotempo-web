require 'test_helper'

class StopTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = Stop.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'get order' do
    o = routes(:route_one_one)
    o.planning.customer.enable_orders = true
    assert_not o.stops[0].order
    assert_not o.stops[1].order

    o.planning.apply_orders(order_arrays(:order_array_one), 0)
    o.planning.save!

    assert_equal [products(:product_one), products(:product_two)], o.stops[0].order.products.to_a
    assert o.stops[1].order.products.empty?
  end

  test 'Create Stops With or Without visit_id' do
    route = routes :route_one_one
    assert ActiveRecord::Base.connection.execute "INSERT INTO stops(active, route_id) VALUES('t', #{route.id});"
    assert_raise ActiveRecord::StatementInvalid do
      assert ActiveRecord::Base.connection.execute "INSERT INTO stops(active, route_id, type) VALUES('t', #{route.id}, '#{StopVisit.name}');"
    end
  end

  test 'should return color and icon of stop visit' do
    o = stops :stop_one_one
    t1 = tags :tag_one

    assert_equal t1.color, o.color
    assert_nil o.icon
    assert_nil o.icon_size
  end

  test 'should return color and icon of stop rest' do
    o = stops :stop_one_four

    assert_nil o.color
    assert_nil o.icon
    assert_nil o.icon_size

    s = stores :store_one
    s.color = '#beef'
    s.icon = 'beef'
    assert s.color, o.color
    assert s.icon, o.icon
    assert_nil o.icon_size
  end
end
