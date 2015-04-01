class V01::Destinations < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def destination_params
      p = ActionController::Parameters.new(params)
      p = p[:destination] if p.key?(:destination)
      p.permit(:ref, :name, :street, :detail, :postalcode, :city, :lat, :lng, :quantity, :take_over, :open, :close, :comment, tag_ids: [])
    end

    def destinations_import_params
      p = ActionController::Parameters.new(params)
      p.permit(:replace, :file)
    end

    Id_desc = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :destinations do
    desc 'Fetch customer\'s destinations.', {
      nickname: 'getDestinations',
      is_array: true,
      entity: V01::Entities::Destination
    }
    get do
      present current_customer.destinations.load, with: V01::Entities::Destination
    end

    desc 'Fetch destination.', {
      nickname: 'getDestination',
      entity: V01::Entities::Destination
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    get ':id' do
      id = read_id(params[:id])
      present current_customer.destinations.where(id).first!, with: V01::Entities::Destination
    end

    desc 'Create destination.', {
      nickname: 'createDestination',
      params: V01::Entities::Destination.documentation.except(:id).merge({
        name: { required: true }
      }),
      entity: V01::Entities::Destination
    }
    post do
      destination = current_customer.destinations.build(destination_params)
      destination.save!
      current_customer.save!
      present destination, with: V01::Entities::Destination
    end

    desc 'Import destinations by upload a CSV file or by JSON', {
      nickname: 'importDestinations',
      params: V01::Entities::DestinationsImport.documentation
    }
    params {
      optional :destinations, type: Array, desc: 'JSON content in mutual exclusion with CSV file upload.'
    }
    put do
      if params['destinations']
        destinations_import = DestinationsImport.new
        destinations_import.assign_attributes({replace: params[:replace]})
        Importer.import_hash(destinations_import.replace, current_customer, params[:destinations])
        status 204
      else
        destinations_import = DestinationsImport.new
        destinations_import.assign_attributes({replace: params[:replace], file: params[:file]})
        if destinations_import.valid?
          Importer.import_csv(destinations_import.replace, current_customer, destinations_import.tempfile, destinations_import.name, synchronous=true)
          status 204
        else
          error!({error: destinations_import.errors.full_messages}, 422)
        end
      end
    end

    desc 'Update destination.', {
      nickname: 'updateDestination',
      params: V01::Entities::Destination.documentation.except(:id),
      entity: V01::Entities::Destination
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    put ':id' do
      id = read_id(params[:id])
      destination = current_customer.destinations.where(id).first!
      destination.assign_attributes(destination_params)
      destination.save!
      destination.customer.save! if destination.customer
      present destination, with: V01::Entities::Destination
    end

    desc 'Delete destination.', {
      nickname: 'deleteDestination'
    }
    params {
      requires :id, type: String, desc: Id_desc
    }
    delete ':id' do
      id = read_id(params[:id])
      current_customer.destinations.where(id).first!.destroy
    end

    desc 'Geocode destination.', {
      nickname: 'geocodeDestination',
      params: V01::Entities::Destination.documentation.except(:id),
      entity: V01::Entities::Destination
    }
    patch 'geocode' do
      destination = Destination.new(destination_params)
      destination.geocode
      present destination, with: V01::Entities::Destination
    end

    if Mapotempo::Application.config.geocode_complete
      desc 'Auto completion on destination.', {
        nickname: 'autocompleteDestination',
        params: V01::Entities::Destination.documentation.except(:id)
      }
      patch 'geocode_complete' do
        p = destination_params
        address_list = Geocode.complete(current_customer.stores[0].lat, current_customer.stores[0].lng, 40000, p[:street], p[:postalcode], p[:city])
        address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
        address_list
      end
    end
  end
end
