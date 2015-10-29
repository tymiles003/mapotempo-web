class ImporterTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  test 'should import store' do
    assert_difference('Store.count') do
      ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_stores_one.csv', 'text')
    end
  end

  test 'should import store with postalcode' do
    assert_difference('Store.count') do
      ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_stores_one_postalcode.csv', 'text')
    end
  end

  test 'should import store with coord' do
    assert_difference('Store.count') do
      ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_stores_one_coord.csv', 'text')
    end
  end

  test 'should import store two' do
    assert_difference('Store.count', 2) do
      ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_stores_two.csv', 'text')
    end
  end

  test 'should import many-utf-8 stores' do
    assert_difference('Store.count', 5) do
      ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_stores_many-utf-8.csv', 'text')
    end
    # o = Store.find{|s| s.customer_id} # many items since we cannot destroy previous
    # assert_equal 'Point 1', o.name
  end

  test 'should import many-iso stores' do
    assert_difference('Store.count', 6) do
      ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_stores_many-iso.csv', 'text')
    end
    # o = Store.find{|s| s.customer_id} # many items since we cannot destroy previous
    # assert_equal 'Point 1', o.name
  end

  test 'should not import store' do
    assert_difference('Store.count', 0) do
      assert_raise RuntimeError do
        ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_invalid.csv', 'text')
      end
    end
  end

  test 'shoud import too many stores' do
    importer_stores = ImporterStores.new(@customer)
    def importer_stores.max_lines
      2
    end
    assert_difference('Store.count', 0) do
      assert_raise RuntimeError do
        importer_stores.import_csv(false, 'test/fixtures/files/import_stores_many-utf-8.csv', 'text')
      end
    end
  end

  test 'should update store' do
    assert_difference('Store.count', 1) do
      ImporterStores.new(@customer).import_csv(false, 'test/fixtures/files/import_stores_update.csv', 'text')
    end
    assert_equal 'unaffected_one_update', Store.find_by(ref:'a').name
    assert_equal 'unaffected_two_update', Store.find_by(ref:'d').name
  end
end
