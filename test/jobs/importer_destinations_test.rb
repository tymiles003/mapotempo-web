class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
    @visit_tag1_count = @customer.visits.select{ |v| v.tags == [tags(:tag_one)] }.size
    @plan_tag1_count = @customer.plannings.select{ |p| p.tags == [tags(:tag_one)] }.size
  end

  def around
    Routers::Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      Routers::Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
        yield
      end
    end
  end

  def tempfile(file, name)
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join(file)),
    })
    file.original_filename = name
    file
  end

  test 'should not import' do
    assert_no_difference('Destination.count') do
      assert_no_difference('Visit.count') do
        assert !ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_invalid.csv', 'text.csv')).import
      end
    end
  end

  test 'should replace with new tag' do
    assert_difference('Tag.count') do
      assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: true, file: tempfile('test/fixtures/files/import_destinations_new_tag.csv', 'text.csv')).import
      assert_equal 1, @customer.destinations.size
      assert_equal 1, @customer.destinations.collect{ |d| d.visits.size }.reduce(&:+)
    end
  end

  test 'should import in new planning' do
    import_count = 1
    # vehicle_usage_set for new planning is hardcoded but random in tests... rest_count depends of it
    VehicleUsageSet.all.each { |v| v.destroy if v.id != vehicle_usage_sets(:vehicle_usage_set_one).id }
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.default_rest_duration }.size
    assert_difference('Planning.count', 1) do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@visit_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_one.csv', 'text.csv')).import

          stop = Planning.last.routes.collect{ |r| r.stops.find{ |s| s.type == 'StopVisit' && s.visit.destination.name == 'BF' } }.compact.first
          assert_equal true, stop.active
          assert_equal 'trace', stop.trace
        end
      end
    end

    assert_equal [tags(:tag_one)], Destination.where(name: 'BF').first.visits.first.destination.tags.to_a
  end

  test 'should import postalcode in new planning' do
    import_count = 1
    # vehicle_usage_set for new planning is hardcoded but random in tests... rest_count depends of it
    VehicleUsageSet.all.each { |v| v.destroy if v.id != vehicle_usage_sets(:vehicle_usage_set_one).id }
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.default_rest_duration }.size
    assert_difference('Planning.count', 1) do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@visit_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_one_postalcode.csv', 'text.csv')).import
        end
      end
    end
  end

  test 'should import coord in new planning' do
    import_count = 1
    # vehicle_usage_set for new planning is hardcoded but random in tests... rest_count depends of it
    VehicleUsageSet.all.each { |v| v.destroy if v.id != vehicle_usage_sets(:vehicle_usage_set_one).id }
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.default_rest_duration }.size
    assert_difference('Planning.count', 1) do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@visit_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_one_coord.csv', 'text.csv')).import
        end
      end
    end
  end

  test 'should import two in new planning' do
    import_count = 2
    # vehicle_usage_set for new planning is hardcoded but random in tests... rest_count depends of it
    VehicleUsageSet.all.each { |v| v.destroy if v.id != vehicle_usage_sets(:vehicle_usage_set_one).id }
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.default_rest_duration }.size
    assert_difference('Planning.count', 1) do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@visit_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_two.csv', 'text.csv')).import
        end
      end
    end

    stops = Planning.where(name: 'text').first.routes.find{ |route| route.ref == '1' }.stops
    assert_equal 'z', stops[1].visit.destination.ref
    assert stops[1].visit.take_over
    assert stops[1].active
    assert_equal 'x', stops[2].visit.destination.ref
    assert_not stops[2].active
  end

  test 'should import without visit' do
    dest_import_count = 2
    visit_tag1_import_count = 1
    assert_no_difference('Planning.count') do
      assert_difference('Destination.count', dest_import_count) do
        assert_difference('Stop.count', visit_tag1_import_count * @plan_tag1_count) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_without_visit.csv', 'text.csv')).import
        end
      end
    end
  end

  test 'should import many-utf-8 in new planning' do
    Planning.all.each(&:destroy)
    planning = @customer.plannings.build(name: 'plan été', vehicle_usage_set: vehicle_usage_sets(:vehicle_usage_set_one), tags: [@customer.tags.build(label: 'été')])
    planning.save!
    @customer.reload
    @customer.destinations.destroy_all
    # destinations with same ref are merged
    import_count = 5
    # vehicle_usage_set for new planning is hardcoded but random in tests... rest_count depends of it
    VehicleUsageSet.all.each { |v| v.destroy if v.id != vehicle_usage_sets(:vehicle_usage_set_one).id }
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.default_rest_duration }.size

    assert_difference('Planning.count', 1) do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', import_count * (@customer.plannings.select{ |p| p.tags.any?{ |t| t.label == 'été' } }.size + 1) + rest_count) do
          di = ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_many-utf-8.csv', 'text.csv'))
          assert di.import, di.errors.messages
          assert_equal 'été', @customer.plannings.collect{ |p| p.tags.collect(&:label).join || 'oups' }.uniq.join
        end
      end
    end

    o = Destination.find{ |d| d.name == 'Point 1' }
    assert_equal ['été'], o.visits.first.destination.tags.collect(&:label)
    p = Planning.first
    assert_equal import_count, p.routes[0].stops.size
    p = Planning.last
    assert_equal 2, p.routes[0].stops.size
    assert_equal 4, p.routes[1].stops.size
  end

  test 'should import many-iso' do
    Planning.all.each(&:destroy)
    @customer.destinations.destroy_all

    # destinations with same ref are merged
    assert_difference('Destination.count', 5) do
      assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_many-iso.csv', 'text.csv')).import
    end

    o = Destination.find_by(name: 'Point 1')
    assert_equal ['été'], o.tags.collect(&:label)
  end

  test 'should import with many visits' do
    dest_import_count = 6
    visit_import_count = 7
    visit_tag1_import_count = 1
    visit_tag2_import_count = 3
    assert_no_difference('Planning.count') do
      assert_difference('Destination.count', dest_import_count) do
        assert_difference('Stop.count',
          visit_import_count * @customer.plannings.select{ |p| p.tags == [] }.size +
          visit_tag1_import_count * @plan_tag1_count +
          visit_tag2_import_count * @customer.plannings.select{ |p| p.tags == [tags(:tag_two)] }.size) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_with_many_visits.csv', 'text.csv')).import
        end
      end
    end
  end

  test 'should replace with many visits' do
    dest_import_count = 6
    visit_import_count = 7
    visit_tag1_import_count = 1
    visit_tag2_import_count = 3
    stop_visit_count = @customer.plannings.collect{ |p| p.routes.collect{ |r| r.stops.select{ |s| s.is_a?(StopVisit) }.size }.reduce(&:+) }.reduce(&:+)
    assert_no_difference('Planning.count') do
      assert_difference('Stop.count', visit_import_count * @customer.plannings.select{ |p| p.tags == [] }.size +
          visit_tag1_import_count * @plan_tag1_count +
          visit_tag2_import_count * @customer.plannings.select{ |p| p.tags == [tags(:tag_two)] }.size -
          stop_visit_count) do
        assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: true, file: tempfile('test/fixtures/files/import_destinations_with_many_visits.csv', 'text.csv')).import
        assert_equal dest_import_count, @customer.destinations.size
      end
    end
  end

  test 'should import and update' do
    assert_difference('Destination.count', 1) do
      ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_update.csv', 'text.csv')).import
    end
    assert_equal 'unaffected_one_update', Destination.find_by(ref:'a').name
    assert_equal 'unaffected_two_update', Destination.find_by(ref:'unknown').name
  end

  test 'should import with route error in new planning' do
    import_count = 2
    # vehicle_usage_set for new planning is hardcoded but random in tests... rest_count depends of it
    VehicleUsageSet.all.each { |v| v.destroy if v.id != vehicle_usage_sets(:vehicle_usage_set_one).id }
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.default_rest_duration }.size
    assert_difference('Planning.count') do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@visit_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          RouterOsrm.stub_any_instance(:trace, lambda{ |*a| raise(RouterError.new('{"status":400,"status_message":"No route found between points"}')) }) do
            assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_two.csv', 'text.csv')).import
          end
        end
      end
    end

    stops = Planning.where(name: 'text').first.routes.find{ |route| route.ref == '1' }.stops
    assert_equal 'z', stops[1].visit.destination.ref
    assert stops[1].visit.take_over
    assert stops[1].active
    assert_equal 'x', stops[2].visit.destination.ref
    assert_not stops[2].active
  end

  test 'should import postalcode in new planning with geocode error' do
    import_count = 1
    # vehicle_usage_set for new planning is hardcoded but random in tests... rest_count depends of it
    VehicleUsageSet.all.each { |v| v.destroy if v.id != vehicle_usage_sets(:vehicle_usage_set_one).id }
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.default_rest_duration }.size
    assert_difference('Planning.count', 1) do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@visit_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          Mapotempo::Application.config.geocode_geocoder.class.stub_any_instance(:code_bulk, lambda{ |*a| raise GeocodeError.new }) do
            assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_one_postalcode.csv', 'text.csv')).import
          end
        end
      end
    end
  end

  test 'should not import too many routes' do
    assert_no_difference('Destination.count') do
      assert_no_difference('Visit.count') do
        assert !ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_too_many_routes.csv', 'text.csv')).import
      end
    end
  end

  test 'should import without header' do
    assert_no_difference('Planning.count') do
      assert_difference('Destination.count', 1) do
        assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, column_def: {name: '2,3', city: '4', lat: '5', lng: '6', tags: '7'}, file: tempfile('test/fixtures/files/import_destinations_without_header.csv', 'text.csv')).import
      end
    end

    o = Destination.find_by(name: 'Point 1')
    assert_equal ['été'], o.tags.collect(&:label)
  end

  test 'should import without header and error column def' do
    assert_no_difference('Planning.count') do
      assert_difference('Destination.count', 1) do
        assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, column_def: {ref: '10000', name: '2,3', city: '4', lat: '5', lng: '6', tags: '7'}, file: tempfile('test/fixtures/files/import_destinations_without_header.csv', 'text.csv')).import
      end
    end

    o = Destination.find_by(name: 'Point 1')
    assert_equal ['été'], o.tags.collect(&:label)
  end

  test 'should not import without header and error column def' do
    assert_no_difference('Destination.count') do
      assert_no_difference('Visit.count') do
        assert !ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, column_def: {ref: '10000'}, file: tempfile('test/fixtures/files/import_destinations_without_header.csv', 'text.csv')).import
      end
    end
  end

  test 'Import Destinations With French Separator (Commas)' do
    assert I18n.locale == :fr
    assert_difference('Destination.count', 1) do
      ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_FR.csv', 'text.csv')).import
    end
    assert Destination.last.lat == 49.173419
    assert Destination.last.lng == -0.326613
    assert Visit.last.quantity == 39.482
  end

end
