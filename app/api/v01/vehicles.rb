class V01::Vehicles < Grape::API
  version '0.1', using: :path

  helpers do
    def current_customer
      @current_user ||= params[:api_key] && User.find_by(api_key: params[:api_key])
      @current_customer ||= @current_user && @current_user.customer
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_customer
      error!('402 Payment Required', 402) if @current_customer.end_subscription && @current_customer.end_subscription > Time.now
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_params
      p = ActionController::Parameters.new(params)
      p = p[:vehicle] if p.has_key?(:vehicle)
      p.permit(:name, :emission, :consumption, :capacity, :color, :open, :close, :tomtom_id, :store_start_id)
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

  resource :vehicles do
    desc "Return customer's vehicles."
    get do
      present current_customer.vehicles.load, with: V01::Entities::Vehicle
    end

    desc "Return a vehicle."
    get ':id' do
      present current_customer.vehicles.find(params[:id]), with: V01::Entities::Vehicle
    end

    desc "Update a vehicle.", {
      params: V01::Entities::Vehicle.documentation.except(:id)
    }
    put ':id' do
      vehicle = current_customer.vehicles.find(params[:id])
      vehicle.update(vehicle_params)
      vehicle.save!
      present vehicle, with: V01::Entities::Vehicle
    end
  end
end
