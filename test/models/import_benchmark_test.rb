require 'test_helper'

require 'benchmark'

if ENV['BENCHMARK'] == 'true'
  class ImportBenchmarkTest < ActiveSupport::TestCase
    setup do
      Mapotempo::Application.config.max_destinations = 30_000

      # Disable logs
      dev_null = Logger.new('/dev/null')
      Rails.logger = dev_null
      ActiveRecord::Base.logger = dev_null

      @customer = customers(:customer_two)
      @customer.max_vehicles = 2_000
      @customer.job_optimizer_id = nil
      @customer.job_destination_geocoding_id = nil
      @customer.save!
      @importer = ImporterDestinations.new(@customer)

      def @importer.max_lines
        30_000
      end
    end

    def around
      Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |_url, _mode, _dimension, segments, _options| segments.collect{ |_| [1000, 60, '_ibE_seK_seK_seK'] } } ) do
        yield
      end
    end

    focus
    test 'should upload 900 destinations in less than 5 minutes (CSV - BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_900.csv'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_900.csv'

      @time_elapsed = Benchmark.realtime do
        import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
        assert import_csv.valid?
        assert import_csv.import
      end.round

      p "Time for uploading 900 points in CSV: #{@time_elapsed} seconds"

      assert @time_elapsed <= 5 * 60
    end

    focus
    test 'should upload 900 destinations in less than 5 minutes (JSON - BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_900.json'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_900.json'

      @time_elapsed = Benchmark.realtime do
        destinations = JSON.parse(file.read)
        import_json = ImportJson.new(importer: @importer, replace: false, json: destinations['destinations'])

        assert import_json.valid?
        assert import_json.import
      end.round

      p "Time for uploading 900 points in JSON: #{@time_elapsed} seconds"

      assert @time_elapsed <= 5 * 60
    end

    focus
    test 'should upload 4000 destinations in less than 12 minutes (CSV - BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_4000.csv'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_4000.csv'

      @time_elapsed = Benchmark.realtime do
        import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
        assert import_csv.valid?
        assert import_csv.import
      end.round

      p "Time for uploading 4000 points in CSV: #{@time_elapsed} seconds"

      assert @time_elapsed <= 12 * 60
    end

    focus
    test 'should upload 4000 destinations in less than 5 minutes (JSON - BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_4000.json'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_4000.json'

      @time_elapsed = Benchmark.realtime do
        destinations = JSON.parse(file.read)
        import_json = ImportJson.new(importer: @importer, replace: false, json: destinations['destinations'])

        assert import_json.valid?
        assert import_json.import
      end.round

      p "Time for uploading 4000 points in JSON: #{@time_elapsed} seconds"

      assert @time_elapsed <= 5 * 60
    end

    focus
    test 'should upload 28 100 destinations in less than 120 minutes (CSV - BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_28100.csv'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_28100.csv'

      @time_elapsed = Benchmark.realtime do
        import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
        assert import_csv.valid?
        assert import_csv.import
      end.round

      p "Time for uploading 28 100 points in CSV: #{@time_elapsed} seconds"

      assert @time_elapsed <= 60 * 60
    end

    focus
    test 'should upload 28 100 destinations in less than 120 minutes (JSON - BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_28100.json'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_28100.json'

      @time_elapsed = Benchmark.realtime do
        destinations = JSON.parse(file.read)
        import_json = ImportJson.new(importer: @importer, replace: false, json: destinations['destinations'])

        assert import_json.valid?
        assert import_json.import
      end.round

      p "Time for uploading 28 100 points in JSON: #{@time_elapsed} seconds"

      assert @time_elapsed <= 60 * 60
    end
  end
end
