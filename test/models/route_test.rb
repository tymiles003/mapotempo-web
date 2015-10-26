require 'test_helper'
require 'osrm'

class D < Struct.new(:lat, :lng, :open, :close, :duration)
  def destination
    self
  end
end

class RouteTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
        yield
      end
    end
  end

  test 'should not save' do
    o = Route.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should dup' do
    o = routes(:route_one_one)
    oo = o.amoeba_dup
    assert_equal oo, oo.stops[0].route
    oo.save!
  end

  test 'should default_stops' do
    o = routes(:route_one_one)
    o.planning.tags.clear
    o.stops.clear
    o.save!
    assert_difference('Stop.count', Destination.all.size) do
      o.default_stops
      o.save!
    end
  end

  test 'should compute' do
    o = routes(:route_one_one)
    o.out_of_date = true
    o.distance = o.emission = o.start = o.end = nil
    o.compute
    assert_not o.out_of_date
    assert o.distance
    assert o.emission
    assert o.start
    assert o.end
    assert_equal o.stops.size + 1, o.distance
    o.save!
  end

  test 'should compute empty' do
    o = routes(:route_one_one)
    assert o.stops.size > 1
    o.compute
    assert_equal o.stops.size + 1, o.distance

    o.stops.each{ |stop|
      stop.active = false
    }

    o.compute
    assert_equal 1, o.distance
    o.save!
  end

  test 'should set destinations' do
    o = routes(:route_one_one)
    o.stops.clear
    assert_difference('Stop.count', 1) do
      o.set_destinations([[destinations(:destination_two), true]])
      o.save!
    end
  end

  test 'should add' do
    o = routes(:route_zero_one)
    o.add(destinations(:destination_two))
    o.save!
    o.reload
    assert o.stops.collect(&:destination).include?(destinations(:destination_two))
  end

  test 'should add index' do
    o = routes(:route_one_one)
    o.add(destinations(:destination_two), 1)
    o.save!
    o.stops.reload
    assert_equal destinations(:destination_two), o.stops.find{ |s| s.destination.name == 'destination_two' }.destination
  end

  test 'should not add without index' do
    o = routes(:route_one_one)
    assert_raises(RuntimeError) {
      o.add(destinations(:destination_two))
    }
  end

  test 'should remove' do
    o = routes(:route_one_one)
    assert_difference('Stop.count', -1) do
      o.remove_destination(destinations(:destination_two))
      o.save!
    end
  end

  test 'should sum_out_of_window' do
    o = routes(:route_one_one)

    o.stops.each { |s|
      if s.is_a?(StopDestination)
        s.destination.open = s.destination.close = nil
        s.destination.save
      else
        s.time = s.open
        s.save
      end
    }
    o.vehicle_usage.open = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.planning.customer.take_over = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.planning.customer.save

    assert_equal 0, o.sum_out_of_window

    o.stops[1].destination.open = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.stops[1].destination.close = Time.new(2000, 01, 01, 00, 00, 00, '+00:00')
    o.stops[1].destination.save
    assert_equal 30, o.sum_out_of_window
  end

  test 'should change active' do
    o = routes(:route_one_one)

    assert_equal 4, o.size_active
    o.active(:none)
    assert_equal 0, o.size_active
    o.active(:all)
    assert_equal 4, o.size_active
    o.stops[0].active = false
    assert_equal 3, o.size_active
    o.active(:foo_bar)
    assert_equal 3, o.size_active

    o.save!
  end

  test 'move stop on same route from inside to start' do
    o = routes(:route_one_one)
    s = o.stops[1]
    assert_equal 2, s.index
    o.move_stop(s, 1)
    o.save!
    s.reload
    assert_equal 1, s.index
  end

  test 'move stop on same route from inside to end' do
    o = routes(:route_one_one)
    s = o.stops[1]
    assert_equal 2, s.index
    o.move_stop(s, 3)
    o.save!
    s.reload
    assert_equal 3, s.index
  end

  test 'move stop on same route from start to inside' do
    o = routes(:route_one_one)
    s = o.stops[0]
    assert_equal 1, s.index
    o.move_stop(s, 2)
    o.save!
    s.reload
    assert_equal 2, s.index
  end

  test 'move stop on same route from end to inside' do
    o = routes(:route_one_one)
    s = o.stops[2]
    assert_equal 3,  s.index
    o.move_stop(s, 2)
    o.save!
    s.reload
    assert_equal 2, s.index
  end

  test 'move stop from unaffected to affected route' do
    o = routes(:route_zero_one)
    s = o.stops[0]
    assert_not s.index
    routes(:route_one_one).move_stop(s, 1)

    o.save!
  end

  test 'move stop from affected to affected route' do
    o = routes(:route_zero_two)
    s = o.stops[0]
    routes(:route_one_one).move_stop(s, 2)

    o.save!
  end

  test 'move stop of unaffected route' do
    o = routes(:route_one_one)
    s = o.stops[1]
    routes(:route_zero_one).move_stop(s, 1)

    o.save!
  end

  test 'should no amalgamate point at same position' do
    o = routes(:route_one_one)

    positions = [D.new(1,1), D.new(2,2), D.new(3,3)]
    ret = o.send(:amalgamate_stops_same_position, positions) { |positions|
      assert_equal 3, positions.size
      pos = positions.sort
      pos.collect{ |p|
        positions.index(p)
      }
    }
    assert_equal positions.size, ret.size
    assert_equal 0.upto(positions.size-1).to_a, ret
  end

  test 'should amalgamate point at same position' do
    o = routes(:route_one_one)

    positions = [D.new(1,1,nil,nil,0), D.new(2,2,nil,nil,0), D.new(2,2,nil,nil,0), D.new(3,3,nil,nil,0)]
    ret = o.send(:amalgamate_stops_same_position, positions) { |positions|
      assert_equal 3, positions.size
      pos = positions.sort
      pos.collect{ |p|
        positions.index(p)
      }
    }
    assert_equal positions.size, ret.size
    assert_equal 0.upto(positions.size-1).to_a, ret
  end

  test 'should amalgamate point at same position, tw' do
    o = routes(:route_one_one)

    positions = [D.new(1,1,nil,nil,0), D.new(2,2,nil,nil,0), D.new(2,2,10,20,0), D.new(3,3,nil,nil,0)]
    ret = o.send(:amalgamate_stops_same_position, positions) { |positions|
      assert_equal 4, positions.size
      (0..(positions.size-1)).to_a
    }
    assert_equal positions.size, ret.size
    assert_equal 0.upto(positions.size-1).to_a, ret
  end

  test 'should optimize' do
    o = routes(:route_one_one)
    optim = o.optimize(nil) { |matrix|
      (0..(matrix.size-1)).to_a
    }
    assert_equal (0..(o.stops.size-1)).to_a, optim
  end

  test 'should optimize whithout store' do
    o = routes(:route_three_one)
    optim = o.optimize(nil) { |matrix|
      (0..(matrix.size-1)).to_a
    }
    assert_equal (0..(o.stops.size-1)).to_a, optim
  end

  test 'should unnil_positions' do
    o = routes(:route_one_one)

    positions = [D.new(1,1,nil,nil,0), D.new(2,2,nil,nil,0), D.new(nil,nil,nil,nil,0), D.new(2,2,10,20,0), D.new(3,3,nil,nil,0)]
    tws = [[nil, nil, 0]] + positions.collect{ |position|
        open, close, duration = position[:open], position[:close], position[:duration]
        open = open ? open - o.vehicle_usage.open.to_i : nil
        close = close ? close - o.vehicle_usage.open.to_i : nil
        if open && close && open > close
          close = open
        end
        [open, close, duration]
      }
    ret = o.send(:unnil_positions, positions, tws){ |positions_loc, tws_loc, rest_tws|
      [0, 1, 2, 3, 4]
    }
    assert_equal ret, [0, 1, 3, 4, 2]
  end

  test 'should unnil_positions except start/stop' do
    o = routes(:route_one_one)

    positions = [D.new(nil,nil,nil,nil,0), D.new(2,2,nil,nil,0), D.new(nil,nil,nil,nil,0), D.new(2,2,10,20,0), D.new(nil,nil,nil,nil,0)]
    tws = [[nil, nil, 0]] + positions.collect{ |position|
        open, close, duration = position[:open], position[:close], position[:duration]
        open = open ? open - o.vehicle_usage.open.to_i : nil
        close = close ? close - o.vehicle_usage.open.to_i : nil
        if open && close && open > close
          close = open
        end
        [open, close, duration]
      }
    ret = o.send(:unnil_positions, positions, tws){ |positions_loc, tws_loc, rest_tws|
      [0, 1, 2, 3, 4]
    }
    assert_equal ret, [0, 1, 3, 4, 2]
  end

  test 'should reverse stops' do
    o = routes(:route_one_one)
    ids = o.stops.collect(&:id)
    o.reverse_order
    assert_equal ids, o.stops.collect(&:id)
  end
end
