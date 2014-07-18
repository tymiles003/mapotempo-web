require "test/unit"

class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  test "shoud import" do
    assert_difference('Planning.count') do
      assert_difference('Destination.count') do
        assert_difference('Stop.count', 1 + 3 + 3) do
          Importer.import(false, @customer, "test/fixtures/files/import_one.csv", "text")
        end
      end
    end
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
end
