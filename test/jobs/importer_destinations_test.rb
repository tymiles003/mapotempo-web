class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
    @destinations_count = @customer.destinations.count
    @plannings_count = @customer.plannings.select{ |planning| planning.tags == [tags(:tag_one)] }.count
  end

  def around
    Osrm.stub_any_instance(:compute, [1, 1, 'trace']) do
      Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
        yield
      end
    end
  end

  test 'shoud import' do
    import_count = 1
    rest_count = 1
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', (@destinations_count + import_count + rest_count) + (import_count + rest_count) * @plannings_count) do
          ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_destinations_one.csv', 'text')
        end
      end
    end

    assert_equal [tags(:tag_one)], Destination.where(name: 'BF').first.tags.to_a
  end

  test 'shoud import postalcode' do
    import_count = 1
    rest_count = 1
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', (@destinations_count + import_count + rest_count) + (import_count + rest_count) * @plannings_count) do
          ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_destinations_one_postalcode.csv', 'text')
        end
      end
    end
  end

  test 'shoud import coord' do
    import_count = 1
    rest_count = 1
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', (@destinations_count + import_count + rest_count) + (import_count + rest_count) * @plannings_count) do
          ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_destinations_one_coord.csv', 'text')
        end
      end
    end
  end

  test 'shoud import two' do
    import_count = 2
    rest_count = 1
    assert_difference('Planning.count') do
      assert_difference('Destination.count', import_count) do
        assert_difference('Stop.count', (@destinations_count + import_count + rest_count) + (import_count + rest_count) * @plannings_count) do
          ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_destinations_two.csv', 'text')
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

  test 'shoud import many-utf-8' do
    Planning.all.each(&:destroy)
    @customer.destinations.destroy_all
    assert_difference('Planning.count') do
      assert_difference('Destination.count', 5) do
        ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_destinations_many-utf-8.csv', 'text')
      end
    end
    o = Destination.find{|d| d.customer_id}
    assert_equal 'Point 1', o.name
    assert_equal ['Nantes'], o.tags.collect(&:label)
    p = Planning.first
    assert_equal 2, p.routes[0].stops.size
  end

  test 'shoud import many-iso' do
    Planning.all.each(&:destroy)
    @customer.destinations.destroy_all
    assert_difference('Destination.count', 6) do
      ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_destinations_many-iso.csv', 'text')
    end
    o = Destination.find{|d| d.customer_id}
    assert_equal 'Point 1', o.name
    assert_equal ['Nantes'], o.tags.collect(&:label)
  end

  test 'shoud not import' do
    assert_difference('Destination.count', 0) do
      assert_raise RuntimeError do
        ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_invalid.csv', 'text')
      end
    end
  end

  test 'shoud import too many' do
    importer_destinations = ImporterDestinations.new
    def importer_destinations.max_lines
      2
    end
    assert_difference('Destination.count', 0) do
      assert_raise RuntimeError do
        importer_destinations.import_csv(false, @customer, 'test/fixtures/files/import_destinations_many-utf-8.csv', 'text')
      end
    end
  end

  test 'shoud update' do
    assert_difference('Destination.count', 1) do
      ImporterDestinations.new.import_csv(false, @customer, 'test/fixtures/files/import_destinations_update.csv', 'text')
    end
    assert_equal 'unaffected_one_update', Destination.find_by(ref:'a').name
    assert_equal 'unaffected_two_update', Destination.find_by(ref:'d').name
  end
end
