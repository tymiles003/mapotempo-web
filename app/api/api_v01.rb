class ApiV01 < Grape::API
  version '0.1', using: :path

  rescue_from ActiveRecord::RecordNotFound do |e|
    rack_response(nil, 404)
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    rack_response({error: e.to_s}.to_json, 400)
  end

  helpers do
    def warden
      env['warden']
    end

    def current_customer(custimer_id = nil)
      @current_user ||= warden.authenticated? && warden.user
      @current_user ||= params[:api_key] && User.find_by(api_key: params[:api_key])
      @current_customer ||= @current_user && (@current_user.admin? && custimer_id ? Customer.find(custimer_id.to_i) : @current_user.customer)
    end

    def authenticate!
      current_customer
      error!('401 Unauthorized', 401) unless @current_user
      error!('402 Payment Required', 402) if @current_customer && @current_customer.end_subscription && @current_customer.end_subscription < Time.now
    end

    def authorize!
    end

    def read_id(raw_id)
      if !raw_id.is_a?(Fixnum) && raw_id.start_with?('ref:')
        {ref: raw_id[4..-1]}
      else
        {id: raw_id.to_i}
      end
    end

    def error!(*args)
      # Workaround for close transaction on error!
      if !ActiveRecord::Base.connection.transaction_manager.current_transaction.is_a?(ActiveRecord::ConnectionAdapters::NullTransaction)
        ActiveRecord::Base.connection.rollback_transaction
      end
      super.error!(*args)
    end
  end

  before do
    authenticate!
    authorize!
    ActiveRecord::Base.connection.begin_transaction
  end

  after do
    begin
      if @error
        ActiveRecord::Base.connection.rollback_transaction
      else
        ActiveRecord::Base.connection.commit_transaction
      end
    rescue Exception
      ActiveRecord::Base.connection.rollback_transaction
      raise
    end
  end

  rescue_from :all do |e|
    @error = e
    Rails.logger.error "\n\n#{e.class} (#{e.message}):\n    " + e.backtrace.join("\n    ") + "\n\n"
    error_response({message: e.message})
  end

  mount V01::Customers
  mount V01::Destinations
  mount V01::OrderArrays
  mount V01::Orders
  mount V01::Plannings
  mount V01::Products
  mount V01::Routes
  mount V01::Stores
  mount V01::Tags
  mount V01::Vehicles
  mount V01::Zonings

  # Tools
  mount V01::Geocoder
end
