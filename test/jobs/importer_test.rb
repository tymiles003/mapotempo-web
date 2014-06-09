require "test/unit"

class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  test "shoud import" do
    Importer.import(true, @customer, "test/fixtures/files/import_one.csv", "text")
  end
end
