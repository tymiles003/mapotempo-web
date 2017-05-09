require 'test_helper'

class V01::PlanningsBaseTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @planning = plannings(:planning_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end
end

class V01::PlanningsTest < V01::PlanningsBaseTest
  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1000, 60, 'trace'] } } ) do
      Routers::RouterWrapper.stub_any_instance(:matrix, lambda{ |url, mode, dimensions, row, column, options| [Array.new(row.size) { Array.new(column.size, 0) }] }) do
        # return all services in reverse order in first route, rests at the end
        OptimizerWrapper.stub_any_instance(:optimize, lambda { |positions, services, vehicles, options| [[]] + vehicles.each_with_index.map{ |v, i| ((i.zero? ? services.reverse : []) + v[:rests]).map{ |s| s[:stop_id] }} }) do
          yield
        end
      end
    end
  end

  test "'should return customer's plannings'" do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @planning.customer.plannings.size, JSON.parse(last_response.body).size
  end

  test "should return customer's plannings by ids" do
    get api(nil, ids: "#{@planning.id},ref:#{plannings(:planning_two).ref}")
    assert last_response.ok?, last_response.body
    body = JSON.parse(last_response.body)
    assert_equal 2, body.size
    assert_includes(body.map { |p| p['id'] }, @planning.id)
    assert_includes(body.map { |p| p['ref'] }, plannings(:planning_two).ref)
  end

  test 'should return a planning' do
    get api(@planning.id)
    assert last_response.ok?, last_response.body
    assert_equal @planning.name, JSON.parse(last_response.body)['name']
  end

  test 'should return a planning by ref' do
    get api("ref:#{@planning.ref}")
    assert last_response.ok?, last_response.body
    assert_equal @planning.ref, JSON.parse(last_response.body)['ref']
  end

  test 'should create a planning' do
    assert_difference('Planning.count', 1) do
      @planning.name = 'new name'
      post api(), @planning.attributes.merge({tag_ids: tags(:tag_one).id, zoning_ids: [zonings(:zoning_one).id]})
      assert last_response.created?, last_response.body
      response = JSON.parse(last_response.body)
      assert_equal 1, response['tag_ids'].size
      assert_equal 1, response['zoning_ids'].size
    end
  end

  test 'should not create a planning with inconsistent data' do
    {
      vehicle_usage_set_id: 0,
      zoning_ids: [zonings(:zoning_three).id]
    }.each{ |k, v|
      attributes = @planning.attributes.merge('name' => 'new name')
      attributes[k] = v
      post api(), attributes
      assert_equal 400, last_response.status
    }
  end

  test 'should update a planning' do
    @planning.name = 'new name'
    put api(@planning.id), @planning.attributes
    assert last_response.ok?, last_response.body

    get api(@planning.id)
    assert last_response.ok?, last_response.body
    assert_equal @planning.name, JSON.parse(last_response.body)['name']
  end

  test 'should destroy a planning' do
    assert_difference('Planning.count', -1) do
      delete api(@planning.id)
      assert_equal 204, last_response.status, last_response.body
    end
  end

  test 'should destroy multiple plannings' do
    assert_difference('Planning.count', -2) do
      delete api + "&ids=#{plannings(:planning_one).id},ref:#{plannings(:planning_two).ref}"
      assert_equal 204, last_response.status, last_response.body
    end
  end

  test 'should force recompute the planning after parameter update' do
    get api("#{@planning.id}/refresh")
    assert last_response.ok?, last_response.body
  end

#  test 'should switch two vehicles' do
#    patch api("#{@planning.id}/switch")
#    assert last_response.ok?, last_response.body
#  end

#  test 'should set stop status' do
#    patch api("#{@planning.id}/update_stop")
#    assert last_response.ok?, last_response.body
#  end

#  test 'should starts asynchronous route optimization' do
#    get api("#{@planning.id}/optimize_route")
#    assert last_response.ok?, last_response.body
#  end

  test 'should change stops activation' do
    patch api("#{@planning.id}/routes/#{@planning.routes[1].id}/active/all")
    assert last_response.ok?, last_response.body
    patch api("#{@planning.id}/routes/#{@planning.routes[1].id}/active/reverse")
    assert last_response.ok?, last_response.body
  end

  test 'should clone planning' do
    assert_difference('Planning.count', 1) do
      patch api("#{@planning.id}/duplicate")
      assert last_response.ok?, last_response.body
    end
  end

  test 'should automatic insert stop with ID from unassigned' do
    unassigned_stop = @planning.routes.detect{ |route| !route.vehicle_usage }.stops.select(&:position?).first
    patch api("#{@planning.id}/automatic_insert"), { stop_ids: [unassigned_stop.id], out_of_zone: true }
    assert_equal 200, last_response.status
    assert @planning.routes.reload.select(&:vehicle_usage).any?{ |route| route.stops.select(&:active).map(&:id).include?(unassigned_stop.id) }
  end

  test 'should automatic insert stop with Ref from existing route with vehicle' do
    last_stop = routes(:route_one_one).stops.select(&:position?).last
    last_stop.update! active: false
    patch api("ref:#{@planning.ref}/automatic_insert"), { stop_ids: [last_stop.id], out_of_zone: true }
    assert_equal 200, last_response.status
    routes = @planning.routes.reload.select(&:vehicle_usage)
    assert routes.any?{ |route| route.stops.select(&:active).map(&:id).include?(last_stop.id) }
    assert routes.all?{ |r| r.stops.collect(&:index).sum == (r.stops.length * (r.stops.length + 1)) / 2 }
  end

  test 'should automatic insert with error' do
    Route.stub_any_instance(:compute, lambda{ |*a| raise }) do
      unassigned_stop = @planning.routes.detect{ |route| !route.vehicle_usage }.stops.select(&:position?).first
      assert_no_difference('Stop.count') do
        patch api("#{@planning.id}/automatic_insert"), { stop_ids: [unassigned_stop.id], out_of_zone: true }
        assert_equal 500, last_response.status
        assert @planning.routes.reload.detect{ |route| !route.vehicle_usage }.stop_ids.include?(unassigned_stop.id)
      end
    end
  end

  test 'Attach Order Array To Planning' do
    order_array = order_arrays :order_array_one
    planning = plannings :planning_one
    assert !planning.order_array
    patch api("#{planning.id}/order_array", order_array_id: order_array.id, shift: 0)
    assert_equal 200, last_response.status
    assert_equal order_array, planning.reload.order_array
  end

  test 'Update Routes' do
    planning = plannings :planning_one
    route = routes :route_one_one
    patch api("#{planning.id}/update_routes"), { route_ids: [route.id], selection: 'all', action: 'toggle' }
    assert last_response.ok?
  end

  test 'should apply zonings' do
    get api("/#{@planning.id}/apply_zonings", { details: true })
    assert last_response.ok?, last_response.body
  end

  test 'should optimize each route' do
    [false, true].each do |sync|
      get api("/#{@planning.id}/optimize", { details: true, synchronous: sync })
      assert last_response.ok?, last_response.body
    end
  end

  test 'should perform a global optimization' do
    [false, true].each do |sync|
      get api("/#{@planning.id}/optimize", { global: true, details: true, synchronous: sync })
      assert last_response.ok?, last_response.body
    end
  end

  test 'should not optimize when a false planning\'s id is given' do
    planning_false_id = Random.new_seed
    [false, true].each do |sync|
      get api("/#{planning_false_id}/optimize", {details: true, synchronous: sync })
      assert_equal 400, last_response.status
    end
  end

  test 'should return a 404 error' do
    planning = plannings :planning_one
    patch "api/0.1/plannings/#{planning.id.to_s}/routes/none/visits/moves.json?api_key=testkey1&visit_ids=47,48"
    assert_equal  404, last_response.status
  end

  test 'should return plannings in any case' do
    planning2 = plannings :planning_two
    ['ics', 'json', 'xml'].each do |ext|
      [nil, "#{@planning.id}, #{planning2.id}", "ref:#{@planning.ref},ref:#{planning2.ref}"].each do |params|
        get "api/0.1/plannings.#{ext}?api_key=testkey1" + (params ? "&ids=#{params}" : '')
        assert last_response.ok?, last_response.body
        if (ext == 'json')
          response = JSON.parse(last_response.body)
          assert_equal 2, response.count
        elsif (ext == 'xml')
          response = last_response.body
          assert_equal 2, response.scan('<id type="integer">').count
        elsif (ext == 'ics')
          response = last_response.body
          stop_count = customers(:customer_one).plannings.flat_map{ |p| p.routes.select(&:vehicle_usage).map{ |r| r.stops.select(&:active?).select(&:position?).select(&:time?).size } }.reduce(&:+)
          assert_equal stop_count, response.scan('BEGIN:VEVENT').count
        end
      end
    end
  end

  test 'should return a 204 header when email=true' do
    get "api/0.1/plannings.ics?api_key=testkey1&ids=1&email=true"
    assert_equal 204, last_response.status
  end

  test 'should update stops status' do
    planning = plannings :planning_one
    patch api("#{planning.id}/update_stops_status")
    assert_equal 204, last_response.status

    patch api("#{planning.id}/update_stops_status", details: true)
    assert_equal 200, last_response.status
  end
end

class V01::PlanningsErrorTest < V01::PlanningsBaseTest

  test 'should perform a global optimization and return no solution found' do
    OptimizerWrapper.stub_any_instance(:optimize, lambda{ |*_a| raise NoSolutionFoundError.new }) do
      get api("/#{@planning.id}/optimize", { global: true, details: true, synchronous: true })
      assert_equal 304, last_response.status, last_response.body
    end
  end

end
