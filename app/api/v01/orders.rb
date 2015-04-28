# Copyright © Mapotempo, 2014-2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
class V01::Orders < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      p = ActionController::Parameters.new(params)
      p = p[:order] if p.key?(:order)
      p.permit(product_ids: [])
    end

    def authorize!
      ability = Ability.new(@current_user)
      error!('401 Unauthorized', 401) unless ability.can?(:manage, OrderArray)
    end
  end

  resource :order_arrays do
    params {
      requires :order_array_id, type: Integer
    }
    segment '/:order_array_id' do

      resource :orders do
        desc 'Fetch order_array\'s orders.', {
          nickname: 'getOrders',
          is_array: true,
          entity: V01::Entities::Order
        }
        get do
          present current_customer.order_arrays.find(params[:order_array_id]).orders.load, with: V01::Entities::Order
        end

        desc 'Fetch order.', {
          nickname: 'getOrder',
          entity: V01::Entities::Order
        }
        params {
          requires :id, type: Integer
        }
        get ':id' do
          present current_customer.order_arrays.find(params[:order_array_id]).orders.find(params[:id]), with: V01::Entities::Order
        end

        desc 'Update order.', {
          nickname: 'updateOrder',
          params: V01::Entities::Order.documentation.except(:id),
          entity: V01::Entities::Order
        }
        params {
          requires :id, type: Integer
        }
        put ':id' do
          order = current_customer.order_arrays.find(params[:order_array_id]).orders.find(params[:id])
          p = order_params
          products = Hash[current_customer.products.collect{ |product| [product.id, product] }]
          products = (p[:product_ids] || []).collect{ |product_id| products[product_id.to_i] }.select{ |i| i }

          order.update(p)
          # Workaround for multiple values need add values and not affect
          order.products.clear
          order.products += products
          order.save!
          present order, with: V01::Entities::Order
        end
      end
    end
  end
end
