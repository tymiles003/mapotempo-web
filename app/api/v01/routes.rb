class V01::Routes < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def route_params
      p = ActionController::Parameters.new(params)
      p = p[:route] if p.key?(:route)
      p.permit(:hidden, :locked, :ref)
    end

    Id_desc = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :plannings do
    params {
      requires :planning_id, type: String, desc: Id_desc
    }
    segment '/:planning_id' do

      resource :routes do
        desc 'Fetch planning\'s routes.', {
          nickname: 'getRoutes',
          is_array: true,
          entity: V01::Entities::Route
        }
        get do
          planning_id = read_id(params[:planning_id])
          present current_customer.plannings.where(planning_id).first!.routes.load, with: V01::Entities::Route
        end

        desc 'Fetch route.', {
          nickname: 'getRoute',
          entity: V01::Entities::Route
        }
        params {
          requires :id, type: Integer
        }
        get ':id' do
          planning_id = read_id(params[:planning_id])
          id = read_id(params[:id])
          present current_customer.plannings.where(planning_id).first!.routes.where(id).first!, with: V01::Entities::Route
        end

        desc 'Update route.', {
          nickname: 'updateRoute',
          params: V01::Entities::Route.documentation.slice(:hidden, :locked),
          entity: V01::Entities::Route
        }
        params {
          requires :id, type: Integer
        }
        put ':id' do
          planning_id = read_id(params[:planning_id])
          id = read_id(params[:id])
          route = current_customer.plannings.where(planning_id).first!.routes.where(id).first!
          route.update(route_params)
          route.save!
          present route, with: V01::Entities::Route
        end

        desc 'Change stops activation.', {
          nickname: 'activationStops',
          entity: V01::Entities::Route
        }
        params {
          requires :id, type: Integer
          requires :active, type: String, values: ['all', 'reverse', 'none']
        }
        patch ':id/active/:active' do
          planning_id = read_id(params[:planning_id])
          planning = current_customer.plannings.where(planning_id).first!
          id = read_id(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }
          if route && route.active(params[:active].to_s.to_sym) && route.compute && planning.save
            present(route, with: V01::Entities::Route)
          end
        end

        desc 'Move destination position in routes.', {
          nickname: 'moveStop'
        }
        params {
          requires :id, type: String
          requires :destination_id, type: String, desc: 'Destination id to move'
          requires :index, type: Integer, desc: 'New position in the route'
        }
        patch ':id/destinations/:destination_id/move/:index' do
          planning_id = read_id(params[:planning_id])
          planning = current_customer.plannings.find{ |planning| planning_id[:ref] ? planning.ref == planning_id[:ref] : planning.id == planning_id[:id] }
          id = read_id(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }
          destination_id = read_id(params[:destination_id])
          destination = current_customer.destinations.find{ |destination| destination_id[:ref] ? destination.ref == destination_id[:ref] : destination.id == id[:id] }

          route.move_destination(destination, params[:index].to_i + 1) && planning.save
        end

        desc 'Move destination to routes. Append in order at end.', {
          nickname: 'moveStops'
        }
        params {
          requires :id, type: String
          requires :destination_ids, type: Array[Integer]
        }
        patch ':id/destinations/moves' do
          planning_id = read_id(params[:planning_id])
          planning = current_customer.plannings.find{ |planning| planning_id[:ref] ? planning.ref == planning_id[:ref] : planning.id == planning_id[:id] }
          id = read_id(params[:id])
          route = planning.routes.find{ |route| id[:ref] ? route.ref == id[:ref] : route.id == id[:id] }


          ids = params[:destination_ids].collect(&:to_i)
          destinations = current_customer.destinations.select{ |destination| ids.include?(destination.id) }

          Planning.transaction do
            destinations.each{ |destination|
              route.move_destination(destination, route.stops.size)
            }
            planning.save
          end
        end

        desc 'Starts asynchronous route optimization.', {
          nickname: 'optimizeRoute'
        }
        params {
          requires :id, type: Integer
        }
        get ':id/optimize' do
          # TODO
          error!('501 Not Implemented', 501)
        end
      end
    end
  end
end
