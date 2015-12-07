class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
    @dest_tag1_count = @customer.destinations.select{ |d| d.tags == [tags(:tag_one)] }.count
    @plan_tag1_count = @customer.plannings.select{ |p| p.tags == [tags(:tag_one)] }.count
  end

  def around
    Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
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

  test 'shoud import in new planning' do
    import_count = 1
    # vehicle_usage_sets for new planning is hardcoded...
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.rest_duration }.count
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', (@dest_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_one.csv', 'text.csv')).import
        end
      end
    end

    assert_equal [tags(:tag_one)], Destination.where(name: 'BF').first.tags.to_a
  end

  test 'shoud import postalcode in new planning' do
    import_count = 1
    # vehicle_usage_sets for new planning is hardcoded...
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.rest_duration }.count
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', (@dest_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_one_postalcode.csv', 'text.csv')).import
        end
      end
    end
  end

  test 'shoud import coord in new planning' do
    import_count = 1
    # vehicle_usage_sets for new planning is hardcoded...
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.rest_duration }.count
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', (@dest_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_one_coord.csv', 'text.csv')).import
        end
      end
    end
  end

  test 'shoud import two in new planning' do
    import_count = 2
    # vehicle_usage_sets for new planning is hardcoded...
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.rest_duration }.count
    assert_difference('Planning.count') do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@dest_tag1_count + (import_count * (@plan_tag1_count + 1)) + rest_count)) do
          assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_two.csv', 'text.csv')).import
        end
      end
    end

    stops = Planning.where(name: 'text').first.routes.find{ |route| route.ref == '1' }.stops
    assert_equal 'z', stops[1].destination.ref
    assert stops[1].destination.take_over
    assert stops[1].active
    assert_equal 'x', stops[2].destination.ref
    assert_not stops[2].active
  end

  test 'shoud import many-utf-8 in new planning' do
    Planning.all.each(&:destroy)
    planning = @customer.plannings.build(name: 'plan été', vehicle_usage_set: vehicle_usage_sets(:vehicle_usage_set_one), tags: [@customer.tags.build(label: 'été')])
    planning.save!
    @customer.reload
    @customer.destinations.destroy_all
    # destinations with same ref are merged
    import_count = 5
    # vehicle_usage_sets for new planning is hardcoded...
    rest_count = @customer.vehicle_usage_sets[0].vehicle_usages.select{ |v| v.rest_duration }.count

    assert_difference('Planning.count', 1) do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', import_count * (@customer.plannings.select{ |p| p.tags.any?{ |t| t.label == 'été' } }.count + 1) + rest_count) do
          di = ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_many-utf-8.csv', 'text.csv'))
          assert di.import, di.errors.messages
          assert_equal 'été', @customer.plannings[0].tags[0].label
        end
      end
    end

    o = Destination.find{|d| d.customer_id}
    assert_equal 'Point 1', o.name
    assert_equal ['été'], o.tags.collect(&:label)
    p = Planning.first
    assert_equal import_count, p.routes[0].stops.size
    p = Planning.last
    assert_equal 2, p.routes[0].stops.size
    assert_equal 4, p.routes[1].stops.size
  end

  test 'shoud import many-iso' do
    Planning.all.each(&:destroy)
    @customer.destinations.destroy_all

    # destinations with same ref are merged
    assert_difference('Destination.count', 5) do
      assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_many-iso.csv', 'text.csv')).import
    end

    o = Destination.find{|d| d.customer_id}
    assert_equal 'Point 1', o.name
    assert_equal ['été'], o.tags.collect(&:label)
  end

  test 'shoud not import' do
    assert_difference('Destination.count', 0) do
      assert !ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_invalid.csv', 'text.csv')).import
    end
  end

  test 'shoud update' do
    assert_difference('Destination.count', 1) do
      assert ImportCsv.new(importer: ImporterDestinations.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_destinations_update.csv', 'text.csv')).import
    end
    assert_equal 'unaffected_one_update', Destination.find_by(ref:'a').name
    assert_equal 'unaffected_two_update', Destination.find_by(ref:'d').name
  end
end
