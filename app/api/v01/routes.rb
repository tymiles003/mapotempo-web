class V01::Routes < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def route_params
      p = ActionController::Parameters.new(params)
      p = p[:route] if p.has_key?(:route)
      p.permit(:hidden, :locked, :ref)
    end
  end

  resource :plannings do
    segment '/:planning_id' do

      resource :routes do
        desc "Return planning's routes."
        get do
          present current_customer.plannings.find(params[:planning_id]).routes.load, with: V01::Entities::Route
        end

        desc 'Return a route.'
        get ':id' do
          present current_customer.plannings.find(params[:planning_id]).routes.find(params[:id]), with: V01::Entities::Route
        end

        desc 'Update a route.', {
          params: V01::Entities::Route.documentation.slice(:hidden, :locked)
        }
        put ':id' do
          route = current_customer.plannings.find(params[:planning_id]).routes.find(params[:id])
          route.update(route_params)
          route.save!
          present route, with: V01::Entities::Route
        end

        desc 'Change stops activation.'
        params {
          requires :active, type: String, desc: 'Value in liste : all, reverse, none'
        }
        patch ':id/active/:active' do
          planning = current_customer.plannings.find(params[:planning_id])
          route = planning.routes.find{ |route| route.id == params[:id].to_i }
          if route && route.active(params[:active].to_s.to_sym) && route.compute && planning.save
            present(route, with: V01::Entities::Route)
          end
        end

        desc 'Move destination position in routes.'
        params {
          requires :destination_id, type: Integer, desc: 'Destination id to move'
          requires :index, type: Integer, desc: 'New position in the route'
        }
        patch ':id/destinations/:destination_id/move/:index' do
          params[:planning_id] = params[:planning_id].to_i
          planning = current_customer.plannings.find{ |planning| planning.id == params[:planning_id] }
          params[:id] = params[:id].to_i
          route = planning.routes.find{ |route| route.id == params[:id] }
          params[:destination_id] = params[:destination_id].to_i
          destination = current_customer.destinations.find{ |destination| destination.id == params[:destination_id] }

          route.move_destination(destination, params[:index].to_i + 1) && planning.save
        end

        desc 'Starts asynchronous route optimization.'
        get ':id/optimize' do
          # TODO
          error!('501 Not Implemented', 501)
        end
      end
    end
  end
end
