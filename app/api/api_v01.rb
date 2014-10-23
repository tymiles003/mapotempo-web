class ApiV01 < Grape::API
  version '0.1', using: :path

  helpers do
    def warden
      env['warden']
    end

    def current_customer
      @current_user ||= warden.authenticated? && warden.user
      @current_user ||= params[:api_key] && User.find_by(api_key: params[:api_key])
      @current_customer ||= @current_user && @current_user.customer
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_customer
      error!('402 Payment Required', 402) if @current_customer.end_subscription && @current_customer.end_subscription > Time.now
    end
  end

  before do
    authenticate!
    ActiveRecord::Base.connection.begin_transaction
  end

  after do
    begin
      ActiveRecord::Base.connection.commit_transaction unless @error
    rescue Exception
      ActiveRecord::Base.connection.rollback_transaction
      raise
    end
  end

  rescue_from :all do |e|
    @error = e
    Rails::logger.error "\n\n#{e.class} (#{e.message}):\n    " + e.backtrace.join("\n    ") + "\n\n"
    error_response({message: e.message})
  end

  mount V01::Customers
  mount V01::Destinations
  mount V01::Plannings
  mount V01::Routes
  mount V01::Stores
  mount V01::Tags
  mount V01::Vehicles
  mount V01::Zonings
end
