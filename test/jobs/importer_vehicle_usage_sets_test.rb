require 'test_helper'

class ImporterVehicleUsageSetsTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  def tempfile(file, name)
    file = ActionDispatch::Http::UploadedFile.new(tempfile: File.new(Rails.root.join(file)))
    file.original_filename = name
    file
  end

  test 'should import vehicle usage set' do
    assert_difference('VehicleUsageSet.count', 1) do
      assert_difference('VehicleUsage.count', 2) do
        assert_no_difference('Vehicle.count') do
          imported_data = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_one.csv', 'text.csv')).import

          assert imported_data
          assert_equal imported_data.first.vehicle_usages.count, imported_data.size - 1
        end
      end
    end
  end

  test 'should import vehicle usage set and replace or not vehicles properties' do
    assert_difference('VehicleUsageSet.count', 1) do
      assert_no_difference('Vehicle.count') do
        imported_data = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: false, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_one.csv', 'text.csv')).import

        assert imported_data
        assert_equal imported_data.second.vehicle.contact_email, 'toto@toto.toto'
        assert_equal imported_data.second.vehicle.consumption, 1.5
        assert_nil imported_data.third.vehicle.contact_email
        assert_equal imported_data.third.vehicle.consumption, 1.5
      end
    end

    assert_difference('VehicleUsageSet.count', 1) do
      assert_no_difference('Vehicle.count') do
        imported_data = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_one.csv', 'text.csv')).import

        assert imported_data
        assert_equal imported_data.second.vehicle.contact_email, 'vehicle1@mapotempo.com'
        assert_equal imported_data.second.vehicle.consumption, 10
        assert_equal imported_data.third.vehicle.contact_email, 'vehicle2@mapotempo.com'
        assert_equal imported_data.third.vehicle.consumption, 15
      end
    end
  end

  test 'should import vehicle usage set and replace the vehicles with same reference' do
    assert_difference('VehicleUsageSet.count', 1) do
      assert_no_difference('Vehicle.count') do
        imported_data = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_with_ref.csv', 'text.csv')).import

        assert imported_data
        assert_equal @customer.vehicles.first.ref, '001'
        assert_equal @customer.vehicles.first.contact_email, 'vehicle1@mapotempo.com'
        assert_equal @customer.vehicles.first.color, '#9000EE'

        assert_nil @customer.vehicles.second.ref
        assert_equal @customer.vehicles.second.contact_email, 'vehicle2@mapotempo.com'
      end
    end
  end

  test 'should import vehicle usage set with new capacities' do
    assert_difference('VehicleUsageSet.count', 1) do
      assert_difference('DeliverableUnit.count', 2) do
        imported_data = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_with_capacities.csv', 'text.csv')).import

        assert imported_data
        assert @customer.deliverable_units.map(&:label).include?('ton')
        assert @customer.deliverable_units.map(&:label).include?('gallon')
      end
    end
  end

  test 'should import vehicle usage set with customed router options' do
    assert_difference('VehicleUsageSet.count', 1) do
      imported_data = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_with_router_options.csv', 'text.csv')).import

      assert imported_data
      assert_equal imported_data.second.vehicle.toll, true
      assert_equal imported_data.second.vehicle.length, '1'
      assert_equal imported_data.third.vehicle.toll, false
      assert_equal imported_data.third.vehicle.length, '10'
    end
  end

  test 'should import vehicle usage set with customed devices' do
    assert_difference('VehicleUsageSet.count', 1) do
      imported_data = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_with_devices.csv', 'text.csv')).import

      assert imported_data
      assert_equal imported_data.second.vehicle.trimble_ref, 'test'
      assert_equal imported_data.second.vehicle.masternaut_ref, 'test'
      assert_equal imported_data.third.vehicle.masternaut_ref, 'test'
      assert_nil imported_data.third.vehicle.trimble_ref
    end
  end

  test 'should not import vehicle usage set without too many vehicles' do
    assert_difference('VehicleUsageSet.count', 0) do
      importer = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_over_max_vehicles.csv', 'text.csv'))

      assert !importer.import
      assert_equal importer.errors[:file][0], I18n.t('destinations.import_file.too_many_lines', n: @customer.max_vehicles + 1)
    end
  end

  test 'should not import vehicle usage set without name' do
    assert_difference('VehicleUsageSet.count', 0) do
      importer = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_without_conf_name.csv', 'text.csv'))

      assert !importer.import
      assert importer.errors[:base][0] =~ /ligne 2/
    end
  end

  test 'should not import vehicle usage set without open/close hours' do
    assert_difference('VehicleUsageSet.count', 0) do
      importer = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_without_open_close.csv', 'text.csv'))

      assert !importer.import
      assert importer.errors[:base][0] =~ /ligne 2/
    end
  end

  test 'should not import vehicle usage set without vehicle name' do
    assert_difference('VehicleUsageSet.count', 0) do
      importer = ImportCsv.new(importer: ImporterVehicleUsageSets.new(@customer), replace_vehicles: true, file: tempfile('test/fixtures/files/import_vehicle_usage_sets_without_vehicle_name.csv', 'text.csv'))

      assert !importer.import
      assert importer.errors[:base][0] =~ /ligne 3/
    end
  end
end
