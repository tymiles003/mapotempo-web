require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1, 1, 'trace'] } } ) do
      yield
    end
  end

  setup do
    @customer = customers(:customer_one)
  end

  test 'should not save' do
    o = Customer.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    o = resellers(:reseller_one).customers.build(name: 'test', max_vehicles: 5, default_country: 'France', router: routers(:router_one), profile: profiles(:profile_one))
    resellers(:reseller_one).save!
    o.max_vehicles = 5
    o.save!
  end

  test 'should stop job optimizer' do
    assert_difference('Delayed::Backend::ActiveRecord::Job.count', -1) do
      @customer.job_optimizer.destroy
    end
  end

  test 'should destination add' do
    c = customers(:customer_one)
    assert_difference('Destination.count') do
      d = c.destinations.build(name: 'new', city: 'Parlà')
      d.visits.build(tags: [tags(:tag_one)])
      c.save!
    end
  end

  test 'should update_out_of_date' do
    o = customers(:customer_one)
    o.take_over = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    o.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle_usage }.each{ |r|
        assert_not r.out_of_date
    }}
    o.save!
    o.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle_usage }.each{ |r|
        assert r.out_of_date
    }}
  end

  test 'should update_max_vehicles up' do
    o = customers(:customer_one)
    assert_difference('Vehicle.count', 1) do
      assert_difference('VehicleUsage.count', o.vehicle_usage_sets.length) do
        assert_difference('Route.count', o.plannings.length) do
          o.max_vehicles += 1
          o.save!
        end
      end
    end
  end

  test 'should update_max_vehicles down' do
    o = customers(:customer_one)
    assert_difference('Vehicle.count', -1) do
      assert_difference('VehicleUsage.count', -o.vehicle_usage_sets.length) do
        assert_difference('Route.count', -o.plannings.length) do
          o.max_vehicles -= 1
          o.save!
        end
      end
    end
  end

  test 'should create and destroy' do
    customer = @customer
    resellers(:reseller_one).save!
    assert customer.stores.size > 0
    assert customer.vehicles.size > 0
    assert customer.vehicle_usage_sets.size > 0
    assert customer.users.size > 0
    assert_difference('Customer.count', -1) do
      assert_difference('User.count', -customer.users.size) do
        customer.destroy
      end
    end
  end

  require Rails.root.join("test/lib/devices/tomtom_base")
  include TomtomBase

  test '[tomtom] change device credentials should update vehicles' do
    @customer = add_tomtom_credentials @customer
    @customer.vehicles.update_all tomtom_id: "tomtom_id"
    @customer.update! tomtom_account: @customer.tomtom_account + "_edit"
    assert @customer.vehicles.all?{|vehicle| !vehicle.tomtom_id }
  end

  test '[tomtom] disable service should update vehicles' do
    @customer = add_tomtom_credentials @customer
    @customer.vehicles.update_all tomtom_id: "tomtom_id"
    @customer.update! enable_tomtom: false
    assert @customer.vehicles.all?{|vehicle| !vehicle.tomtom_id }
  end

  require Rails.root.join("test/lib/devices/teksat_base")
  include TeksatBase

  test '[teksat] change device credentials should update vehicles' do
    @customer = add_teksat_credentials @customer
    @customer.vehicles.update_all teksat_id: "teksat_id"
    @customer.update! teksat_customer_id: Time.now.to_i
    assert @customer.vehicles.all?{|vehicle| !vehicle.teksat_id }
  end

  test '[teksat] disable service should update vehicles' do
    @customer = add_teksat_credentials @customer
    @customer.vehicles.update_all teksat_id: "teksat_id"
    @customer.update! enable_teksat: false
    assert @customer.vehicles.all?{|vehicle| !vehicle.teksat_id }
  end

  require Rails.root.join("test/lib/devices/orange_base")
  include OrangeBase

  test '[orange] change device credentials should update vehicles' do
    @customer = add_orange_credentials @customer
    @customer.vehicles.update_all orange_id: "orange_id"
    @customer.update! orange_user: @customer.orange_user + "_edit"
    assert @customer.vehicles.all?{|vehicle| !vehicle.orange_id }
  end

  test '[orange] disable service should update vehicles' do
    @customer = add_teksat_credentials @customer
    @customer.vehicles.update_all orange_id: "orange_id"
    @customer.update! enable_orange: false
    assert @customer.vehicles.all?{|vehicle| !vehicle.orange_id }
  end

  test 'should get router dimension' do
    assert_equal 'time', @customer.router_dimension
  end

  test 'customer with order array' do
    planning = plannings :planning_one
    order_array = order_arrays :order_array_one
    planning.update! order_array: order_array
    products = Product.find ActiveRecord::Base.connection.select_all("SELECT product_id FROM orders_products WHERE order_id IN (%s)" % [ order_array.order_ids.join(",") ]).rows
    assert products.any?
    assert planning.customer.destroy
  end

  test 'should update enable_multi_visits' do
    customer = @customer
    refs = customer.destinations.collect(&:ref)
    tags = customer.destinations.collect{ |d| d.tags.collect(&:label) }.flatten
    assert_no_difference('Destination.count') do
      assert_no_difference('Visit.count') do
        customer.enable_multi_visits = true
        customer.save
        assert_equal refs, customer.destinations.collect{ |d| d.visits.collect(&:ref) }.flatten
        assert_equal tags, customer.destinations.collect{ |d| d.visits.collect{ |v| v.tags.collect(&:label)}.flatten }.flatten
      end
    end
    assert_no_difference('Destination.count') do
      assert_no_difference('Visit.count') do
        customer.enable_multi_visits = false
        customer.save
        assert_equal refs, customer.destinations.collect(&:ref)
        assert_equal tags, customer.destinations.collect{ |d| d.tags.collect(&:label) }.flatten
      end
    end
  end

  test 'should duplicate' do
    duplicate = nil

    assert_difference('Customer.count', 1) do
      assert_difference('User.count', @customer.users.size) do
        assert_difference('Planning.count', @customer.plannings.size) do
          assert_difference('Destination.count', @customer.destinations.size) do
            assert_difference('Vehicle.count', @customer.vehicles.size) do
              assert_difference('Zoning.count', @customer.zonings.size) do
                assert_difference('Tag.count', @customer.tags.size) do
                  # assert_difference('OrderArray.count', @customer.order_arrays.size) do
                    duplicate = @customer.duplicate
                    duplicate.save!
                  # end
                end
              end
            end
          end
        end
      end
    end

    duplicate.reload

    assert_difference('Customer.count', -1) do
      assert_difference('User.count', -@customer.users.size) do
        assert_difference('Planning.count', -@customer.plannings.size) do
          assert_difference('Destination.count', -@customer.destinations.size) do
            assert_difference('Vehicle.count', -@customer.vehicles.size) do
              assert_difference('Zoning.count', -@customer.zonings.size) do
                assert_difference('Tag.count', -@customer.tags.size) do
                  # assert_difference('OrderArray.count', -@customer.order_arrays.size) do
                    duplicate.destroy!
                  # end
                end
              end
            end
          end
        end
      end
    end
  end
end
