class V01::Destinations < Grape::API
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
    def destination_params
      p = ActionController::Parameters.new(params)
      p = p[:destination] if p.has_key?(:destination)
      p.permit(:ref, :name, :street, :detail, :postalcode, :city, :lat, :lng, :quantity, :take_over, :open, :close, :comment, :tag_ids => [])
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

  resource :destinations do
    desc "Return customer's destinations."
    get do
      present current_customer.destinations.load, with: V01::Entities::Destination
    end

    desc "Return a destination."
    get ':id' do
      present current_customer.destinations.find(params[:id]), with: V01::Entities::Destination
    end

    desc "Create a destination.", {
      params: V01::Entities::Destination.documentation.except(:id)
    }
    post  do
      destination = current_customer.destinations.build(destination_params)
      current_customer.save!
      present destination, with: V01::Entities::Destination
    end

    desc "Update a destination.", {
      params: V01::Entities::Destination.documentation.except(:id)
    }
    put ':id' do
      destination = current_customer.destinations.find(params[:id])
      destination.assign_attributes(destination_params)
      destination.reverse_geocode if params.has_key?(:reverse)
      destination.save!
      destination.customer.save! if destination.customer
      present destination, with: V01::Entities::Destination
    end

    desc "Destroy a destination."
    delete ':id' do
      current_customer.destinations.find(params[:id]).destroy
    end

    desc "Geocode a destination.", {
      params: V01::Entities::Destination.documentation.except(:id)
    }
    patch 'geocode' do
      destination = Destination.new(destination_params)
      destination.geocode
      present destination, with: V01::Entities::Destination
    end

    desc "Reverse geocode a destination.", {
      params: V01::Entities::Destination.documentation.except(:id)
    }
    patch 'geocode_reverse' do
      destination = Destination.new(destination_params)
      destination.reverse_geocode
      present destination, with: V01::Entities::Destination
    end

    if Mapotempo::Application.config.geocode_complete
      desc "Auto completion on destination.", {
        params: V01::Entities::Destination.documentation.except(:id)
      }
      patch 'geocode_complete' do
        p = destination_params
        address_list = Geocode.complete(current_customer.store.lat, current_customer.store.lng, 40000, p[:street], p[:postalcode], p[:city])
        address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
        address_list
      end
    end
  end
end
