class V01::Zonings < Grape::API
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
    def zoning_params
      p = ActionController::Parameters.new(params)
      p = p[:zoning] if p.has_key?(:zoning)
      p.permit(:name, zones_attributes: [:id, :polygon, :_destroy, vehicle_ids: []])
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

  resource :zonings do
    desc "Return customer's zonings."
    get do
      present current_customer.zonings.load, with: V01::Entities::Zoning
    end

    desc "Return a zoning."
    get ':id' do
      present current_customer.zonings.find(params[:id]), with: V01::Entities::Zoning
    end

    desc "Create a zoning.", {
      params: V01::Entities::Zoning.documentation.except(:id)
    }
    post  do
      zoning = current_customer.zonings.build(zoning_params)
      zoning.save!
      present zoning, with: V01::Entities::Zoning
    end

    desc "Update a zoning.", {
      params: V01::Entities::Zoning.documentation.except(:id)
    }
    put ':id' do
      zoning = current_customer.zonings.find(params[:id])
      zoning.update(zoning_params)
      zoning.save!
      present zoning, with: V01::Entities::Zoning
    end

    desc "Destroy a zoning."
    delete ':id' do
      current_customer.zonings.find(params[:id]).destroy
    end
  end
end
