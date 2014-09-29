class V01::Routes < Grape::API
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def route_params
      p = ActionController::Parameters.new(params)
      p = p[:route] if p.has_key?(:route)
      p.permit(:hidden, :locked)
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

  resource :plannings do
    segment '/:planning_id' do

      resource :routes do
        desc "Return customer's routes."
        get do
          present current_customer.plannings.find(params[:planning_id]).routes.load, with: V01::Entities::Route
        end

        desc "Return a route."
        get ':id' do
          present current_customer.plannings.find(params[:planning_id]).routes.find(params[:id]), with: V01::Entities::Route
        end

        desc "Update a route.", {
          params: V01::Entities::Route.documentation.slice(:hidden, :locked)
        }
        put ':id' do
          route = current_customer.plannings.find(params[:planning_id]).routes.find(params[:id])
          route.update(route_params)
          route.save!
          present route, with: V01::Entities::Route
        end
      end
    end
  end
end
