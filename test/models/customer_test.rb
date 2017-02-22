require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |_url, _mode, _dimension, segments, _options| segments.collect{ |_i| [1, 1, '_ibE_seK_seK_seK'] } } ) do
      yield
    end
  end

  setup do
    @customer = customers(:customer_one)
  end

  test 'should not save' do
    customer = Customer.new
    assert_not customer.save, 'Saved without required fields'
  end

  test 'should save' do
    reseller = resellers(:reseller_one)
    customer = reseller.customers.build(name: 'test', max_vehicles: 5, default_country: 'France', router: routers(:router_one), profile: profiles(:profile_one))
    assert_difference('Customer.count', 1) do
      assert_difference('Vehicle.count', 5) do
        assert_difference('Vehicle.count', 5) do
          assert_difference('VehicleUsageSet.count', 1) do
            assert_difference('DeliverableUnit.count', 1) do
              assert_difference('Store.count', 1) do
                reseller.save!
              end
            end
          end
        end
      end
    end

    assert customer.test, Mapotempo::Application.config.customer_test_default
  end

  test 'should stop job optimizer' do
    assert_difference('Delayed::Backend::ActiveRecord::Job.count', -1) do
      @customer.job_optimizer.destroy
    end
  end

  test 'should destination add' do
    customer = customers(:customer_one)
    assert_difference('Destination.count') do
      destination = customer.destinations.build(name: 'new', city: 'Parlà')
      destination.visits.build(tags: [tags(:tag_one)])
      customer.save!
    end
  end

  test 'should update_out_of_date' do
    customer = customers(:customer_one)
    customer.take_over = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    customer.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle_usage }.each{ |r|
        assert_not r.out_of_date
    }}
    customer.save!
    customer.plannings.each{ |p|
      p.routes.select{ |r| r.vehicle_usage }.each{ |r|
        assert r.out_of_date
    }}
  end

  test 'should update max vehicles up' do
    assert !Mapotempo::Application.config.manage_vehicles_only_admin
    customer = customers(:customer_one)
    assert_difference('Vehicle.count', 1) do
      assert_difference('VehicleUsage.count', customer.vehicle_usage_sets.length) do
        assert_difference('Route.count', customer.plannings.length) do
          customer.max_vehicles += 1
          customer.save!
        end
      end
    end
  end

  test 'should update max vehicles down' do
    assert !Mapotempo::Application.config.manage_vehicles_only_admin
    customer = customers(:customer_one)
    assert_difference('Vehicle.count', -1) do
      assert_difference('VehicleUsage.count', -customer.vehicle_usage_sets.length) do
        assert_difference('Route.count', -customer.plannings.length) do
          customer.max_vehicles -= 1
          customer.save!
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
    unit_ids = @customer.deliverable_units.map(&:id)

    assert_difference('Customer.count', 1) do
      assert_difference('User.count', @customer.users.size) do
        assert_difference('Planning.count', @customer.plannings.size) do
          assert_difference('Destination.count', @customer.destinations.size) do
            assert_difference('Vehicle.count', @customer.vehicles.size) do
              assert_difference('Zoning.count', @customer.zonings.size) do
                assert_difference('Tag.count', @customer.tags.size) do
                  assert_difference('DeliverableUnit.count', @customer.deliverable_units.size) do
                    # assert_difference('OrderArray.count', @customer.order_arrays.size) do
                      duplicate = @customer.duplicate
                      duplicate.save!

                      assert_equal @customer.vehicles.map{ |v| v.capacities.delete_if{ |k, v| unit_ids.exclude? k }.values }, duplicate.vehicles.map{ |v| v.capacities.values }
                      assert_equal [], @customer.vehicles.map{ |v| v.capacities.delete_if{ |k, v| unit_ids.exclude? k }.keys } & duplicate.vehicles.map{ |v| v.capacities.keys }

                      assert_equal @customer.destinations.flat_map{ |dest| dest.visits.map{ |v| v.quantities.delete_if{ |k, v| unit_ids.exclude? k }.values }}, duplicate.destinations.flat_map{ |dest| dest.visits.map{ |v| v.quantities.values }}
                      assert_equal [], @customer.destinations.flat_map{ |dest| dest.visits.flat_map{ |v| v.quantities.delete_if{ |k, v| unit_ids.exclude? k }.keys }} & duplicate.destinations.flat_map{ |dest| dest.visits.flat_map{ |v| v.quantities.keys }}

                      assert duplicate.test, Mapotempo::Application.config.customer_test_default
                    # end
                  end
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
                  assert_difference('DeliverableUnit.count', -@customer.deliverable_units.size) do
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
end
