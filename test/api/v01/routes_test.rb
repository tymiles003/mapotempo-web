require 'test_helper'

class V01::RoutesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @route = routes(:route_one_one)
  end

  def around
    Routers::Osrm.stub_any_instance(:compute, [1000, 60, 'trace']) do
      Routers::Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
        Ort.stub_any_instance(:optimize, lambda { |matrix, dimension, services, stores, rests, optimize_time, soft_upper_bound, cluster_time_threshold| (0..(matrix.size-1)).to_a.reverse }) do
          yield
        end
      end
    end
  end

  def api(planning_id, part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings/#{planning_id}/routes#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s routes' do
    get api(@route.planning.id)
    assert last_response.ok?, last_response.body
    assert_equal @route.planning.routes.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s routes by ids' do
    get api(@route.planning.id, nil, 'ids' => @route.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @route.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a route' do
    get api(@route.planning.id, @route.id)
    assert last_response.ok?, last_response.body
    stops = JSON.parse(last_response.body)['stops']
    assert_equal @route.stops.size, stops.size
    assert_equal '2015-10-10T00:00:30', stops[0]['time']
  end

  test 'should update a route' do
    @route.locked = true
    put api(@route.planning.id, @route.id), @route.attributes
    assert last_response.ok?, last_response.body

    get api(@route.planning.id, @route.id)
    assert last_response.ok?, last_response.body
    assert_equal @route.locked, JSON.parse(last_response.body)['locked']
  end

  test 'should move stop position in routes' do
    patch api(@route.planning.id, "#{@route.id}/stops/#{@route.planning.routes[0].stops[0].id}/move/1")
    assert_equal 204, last_response.status, last_response.body
  end

  test 'should change stops activation' do
    patch api(@route.planning.id, "#{@route.id}/active/reverse")
    assert last_response.ok?, last_response.body
  end

  test 'should move visits in routes' do
    assert_no_difference('Stop.count') do
      patch api(@route.planning.id, routes(:route_three_one).id.to_s + "/visits/moves"), visit_ids: [visits(:visit_two).id, visits(:visit_one).id]
      assert_equal 204, last_response.status, last_response.body
      assert_equal visits(:visit_two).ref, routes(:route_three_one).stops[0].visit.ref
      assert_equal visits(:visit_one).ref, routes(:route_three_one).stops[1].visit.ref
    end
  end

  test 'should move visits in routes with error' do
    assert_no_difference('Stop.count') do
      Route.stub_any_instance(:compute, lambda{ |*a| raise }) do
        visit_one = visits(:visit_one)
        visit_two = visits(:visit_two)
        patch api(@route.planning.id, routes(:route_three_one).id.to_s + "/visits/moves"), visit_ids: [visit_two.id, visit_one.id]
        assert_equal 500, last_response.status, last_response.body
        assert visit_two.stop_visits.find{ |s| s.route_id == routes(:route_one_one).id }
        assert visit_one.stop_visits.find{ |s| s.route_id == routes(:route_one_one).id }
      end
    end
  end

  test 'should optimize route' do
    default_order = @route.stops.collect(&:id)

    patch api(@route.planning.id, "#{@route.id}/optimize")
    assert_equal 204, last_response.status, last_response.body

    get api(@route.planning.id, @route.id)
    assert_equal default_order.reverse, JSON.parse(last_response.body)['stops'].collect{ |s| s['id'] }
  end

  test 'should optimize route with details' do
    patch api(@route.planning.id, "#{@route.id}/optimize", details: true)
    assert_equal 200, last_response.status, last_response.body
    assert JSON.parse(last_response.body)['id']
  end

  test 'should return a route from vehicle from Ref JSON' do
    get "/api/0.1/plannings/#{@route.planning.id}/routes_by_vehicle/ref:" + vehicles(:vehicle_one).ref + ".json?api_key=testkey1"
    assert last_response.ok?, last_response.body
    stops = JSON.parse(last_response.body)['stops']
    assert_equal @route.stops.size, stops.size
    assert_equal '2015-10-10T00:00:30', stops[0]['time']
  end

  test 'should return a route from vehicle from ID JSON' do
    get "/api/0.1/plannings/#{@route.planning.id}/routes_by_vehicle/" + vehicles(:vehicle_one).id.to_s + ".json?api_key=testkey1"
    assert last_response.ok?, last_response.body
    stops = JSON.parse(last_response.body)['stops']
    assert_equal @route.stops.size, stops.size
    assert_equal '2015-10-10T00:00:30', stops[0]['time']
  end

  test 'should return a route from vehicle from Ref XML' do
    get "/api/0.1/plannings/#{@route.planning.id}/routes_by_vehicle/ref:" + vehicles(:vehicle_one).ref + ".xml?api_key=testkey1"
    assert last_response.ok?, last_response.body
    stops = Hash.from_xml(last_response.body)["hash"]["stops"]
    assert_equal @route.stops.size, stops.size
    assert_equal '2015-10-10T00:00:30', stops[0]['time']
  end

  test 'should return a route from vehicle from ID XML' do
    get "/api/0.1/plannings/#{@route.planning.id}/routes_by_vehicle/" + vehicles(:vehicle_one).id.to_s + ".xml?api_key=testkey1"
    assert last_response.ok?, last_response.body
    stops = Hash.from_xml(last_response.body)["hash"]["stops"]
    assert_equal @route.stops.size, stops.size
    assert_equal '2015-10-10T00:00:30', stops[0]['time']
  end

  test 'should not return route because IDs are invalid' do
    get "/api/0.1/plannings/Abcd/routes_by_vehicle/test1111.json?api_key=testkey1"
    assert_equal(400, last_response.status)
    assert_equal({ "error" => "Invalid IDs" }, JSON.parse(last_response.body))
  end

  test 'should not return route because not found' do
    get "/api/0.1/plannings/1234/routes_by_vehicle/1234.json?api_key=testkey1"
    assert_equal(404, last_response.status)
    assert_equal({ "error" => "Not Found" }, JSON.parse(last_response.body))
  end

end
