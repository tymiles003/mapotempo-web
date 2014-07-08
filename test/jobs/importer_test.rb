require "test/unit"

class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  test "shoud import" do
    assert_difference('Destination.count', 1) do
      Importer.import(false, @customer, "test/fixtures/files/import_one.csv", "text")
    end
  end

  test "shoud not import" do
    assert_difference('Destination.count', 0) do
      assert_raise RuntimeError do
        Importer.import(false, @customer, "test/fixtures/files/import_invalid.csv", "text")
      end
    end
  end
end
