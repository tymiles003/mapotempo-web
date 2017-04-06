require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    store = Store.new
    assert_not store.save, 'Saved without required fields'
  end

  test 'should save' do
    store = customers(:customer_one).stores.build(name: 'plop', city: 'Bordeaux', state: 'Midi-Pyrénées')
    assert store.save!
    store.reload
    assert !store.lat.nil?, 'Latitude not built'
  end

  test 'should destroy' do
    store = customers(:customer_one)
    assert_difference('store.stores.size', -1) do
      store = store.stores.find{ |s| s[:name] == 'store 0' }
      assert store.destroy
      store.reload
      assert_equal stores(:store_one), vehicle_usages(:vehicle_usage_one_one).store_start
    end
  end

  test 'should destroy in use for vehicle_usage' do
    store = customers(:customer_one)
    assert_difference('store.stores.size', -1) do
      store = store.stores.find{ |s| s[:name] == 'store 1' }
      assert store.destroy
      store.reload
      assert_not_equal store, vehicle_usages(:vehicle_usage_one_one).store_start
    end
  end

  test 'should not destroy last store' do
    store = customers(:customer_one)
    assert_not_equal 0, store.stores.size
    for i in 0..(store.stores.size - 2)
      assert store.stores[i].destroy
    end
    store.reload
    begin
      store.stores[0].destroy!
      assert false
    rescue
      assert true
    end
  end

  test 'should out_of_date' do
    store = stores(:store_one)
    assert_not store.customer.plannings.where(name: 'planning1').first.out_of_date
    store.lat = 10.1
    store.save!
    store.reload
    assert store.customer.plannings.where(name: 'planning1').first.out_of_date
  end

  test 'should geocode' do
    store = stores(:store_one)
    lat, lng = store.lat, store.lng
    store.geocode
    assert store.lat
    assert_not_equal lat, store.lat
    assert store.lng
    assert_not_equal lng, store.lng
  end

  test 'should geocode with error' do
    Mapotempo::Application.config.geocode_geocoder.class.stub_any_instance(:code, lambda{ |*a| raise GeocodeError.new }) do
      store = stores(:store_one)
      assert store.geocode
      assert 1, store.warnings.size
    end
  end

  test 'should update_geocode' do
    store = stores(:store_one)
    store.city = 'Toulouse'
    store.state = 'Midi-Pyrénées'
    store.lat = store.lng = nil
    lat, lng = store.lat, store.lng
    store.save!
    assert store.lat
    assert_not_equal lat, store.lat
    assert store.lng
    assert_not_equal lng, store.lng
  end

  test 'should update_geocode with error' do
    Mapotempo::Application.config.geocode_geocoder.class.stub_any_instance(:code, lambda{ |*a| raise GeocodeError.new }) do
      store = stores(:store_one)
      store.city = 'Toulouse'
      store.state = 'Midi-Pyrénées'
      store.lat = store.lng = nil
      assert store.save!
      assert 1, store.warnings.size
    end
  end

  test 'should distance' do
    store = stores(:store_one)
    assert_equal 2.51647173560523, store.distance(stores(:store_two))
  end

  test 'should return default color' do
    store = stores :store_one

    assert_equal Store::COLOR_DEFAULT, store.default_color
    assert_equal Store::ICON_DEFAULT, store.default_icon
    assert_equal Store::ICON_SIZE_DEFAULT, store.default_icon_size

    store.color = '#beef'
    store.icon = 'beef'
    assert_equal store.color, store.default_color
    assert_equal store.icon, store.default_icon
    assert_equal Store::ICON_SIZE_DEFAULT, store.default_icon_size
  end
end
