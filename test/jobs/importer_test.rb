class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  test "shoud import" do
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', 1 + 0 + (1 + 2 + 1)) do
          Importer.import(false, @customer, "test/fixtures/files/import_one.csv", "text")
        end
      end
    end

    assert_equal [tags(:tag_one)], Destination.where(name: "BF").first.tags.to_a
  end

  test "shoud import tow" do
    assert_difference('Planning.count') do
      assert_difference('Destination.count', 2) do
        assert_difference('Stop.count', 1 + 4 + 2) do
          Importer.import(false, @customer, "test/fixtures/files/import_two.csv", "text")
        end
      end
    end

    stops = Planning.where(name: "text").first.routes[1].stops
    assert 'a', stops[1].destination.ref
    assert stops[1].destination.take_over
    assert stops[1].active
    assert 'b', stops[2].destination.ref
    assert_not stops[2].active
  end

  test "shoud import many-utf-8" do
    Planning.all.each(&:destroy)
    @customer.destinations.destroy_all
    assert_difference('Destination.count', 5) do
      Importer.import(false, @customer, "test/fixtures/files/import_many-utf-8.csv", "text")
    end
    o = Destination.find{|d| d.customer_id}
    assert_equal "Point 1", o.name
    assert_equal ["Nantes"], o.tags.collect(&:label)
  end

  test "shoud import many-iso" do
    Planning.all.each(&:destroy)
    @customer.destinations.destroy_all
    assert_difference('Destination.count', 6) do
      Importer.import(false, @customer, "test/fixtures/files/import_many-iso.csv", "text")
    end
    o = Destination.find{|d| d.customer_id}
    assert_equal "Point 1", o.name
    assert_equal ["Nantes"], o.tags.collect(&:label)
  end

  test "shoud not import" do
    assert_difference('Destination.count', 0) do
      assert_raise RuntimeError do
        Importer.import(false, @customer, "test/fixtures/files/import_invalid.csv", "text")
      end
    end
  end

  test "shoud update" do
    assert_difference('Destination.count', 1) do
      Importer.import(false, @customer, "test/fixtures/files/import_update.csv", "text")
    end
    assert_equal 'unaffected_one_update', Destination.find_by(ref:'a').name
    assert_equal 'unaffected_two_update', Destination.find_by(ref:'d').name
  end
end
