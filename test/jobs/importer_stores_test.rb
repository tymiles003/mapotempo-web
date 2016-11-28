class ImporterStoresTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  def tempfile(file, name)
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join(file)),
    })
    file.original_filename = name
    file
  end

  test 'should import store' do
    assert_difference('Store.count') do
      assert ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_stores_one.csv', 'text.csv')).import
    end
  end

  test 'should import store with postalcode' do
    assert_difference('Store.count') do
      assert ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_stores_one_postalcode.csv', 'text.csv')).import
    end
  end

  test 'should import store with coord' do
    assert_difference('Store.count') do
      assert ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_stores_one_coord.csv', 'text.csv')).import
    end
  end

  test 'should import store two' do
    assert_difference('Store.count', 2) do
      assert ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_stores_two.csv', 'text.csv')).import
    end
  end

  test 'should import many-utf-8 stores' do
    assert_difference('Store.count', 5) do
      assert ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_stores_many-utf-8.csv', 'text.csv')).import
    end
    # o = Store.find{|s| s.customer_id} # many items since we cannot destroy previous
    # assert_equal 'Point 1', o.name
  end

  test 'should import many-iso stores' do
    assert_difference('Store.count', 6) do
      assert ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_stores_many-iso.csv', 'text.csv')).import
    end
    # o = Store.find{|s| s.customer_id} # many items since we cannot destroy previous
    # assert_equal 'Point 1', o.name
  end

  test 'should not import store' do
    assert_difference('Store.count', 0) do
     assert !ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_invalid.csv', 'text.csv')).import
    end
  end

  test 'should update store' do
    assert_difference('Store.count', 1) do
      assert ImportCsv.new(importer: ImporterStores.new(@customer), replace: false, file: tempfile('test/fixtures/files/import_stores_update.csv', 'text.csv')).import
    end
    assert_equal 'unaffected_one_update', Store.find_by(ref:'a').name
    assert_equal 'unaffected_two_update', Store.find_by(ref:'unknown').name
  end
end
