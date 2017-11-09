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

    test 'should upload 28 100 points with 165 vehicles in less than 1 hour (BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark.csv'))
                                                    })
      file.original_filename = 'import_destinations_benchmark.csv'

      @time_elapsed = Benchmark.realtime do
        import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
        assert import_csv.valid?
        assert import_csv.import
      end.round

      assert @time_elapsed <= 60 * 60
    end
  end
end
