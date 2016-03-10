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
require 'coerce'

class V01::OrderArrays < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def order_array_params
      p = ActionController::Parameters.new(params)
      p = p[:order_array] if p.key?(:order_array)
      p.permit(:name, :base_date, :length)
    end

    def authorize!
      ability = Ability.new(@current_user)
      error!('401 Unauthorized', 401) unless ability.can?(:manage, OrderArray)
    end
  end

  resource :order_arrays do
    desc 'Fetch customer\'s order_arrays.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'getOrderArrays',
      is_array: true,
      entity: V01::Entities::OrderArray
    params do
      optional :ids, type: Array[Integer], desc: 'Select returned order_arrays by id.', coerce_with: CoerceArrayInteger
    end
    get do
      order_arrays = if params.key?(:ids)
        current_customer.order_arrays.select{ |order_array| params[:ids].include?(order_array.id) }
      else
        current_customer.order_arrays.load
      end
      present order_arrays, with: V01::Entities::OrderArray
    end

    desc 'Fetch order_array.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'getOrderArray',
      entity: V01::Entities::OrderArray
    params do
      requires :id, type: Integer
    end
    get ':id' do
      present current_customer.order_arrays.find(params[:id]), with: V01::Entities::OrderArray
    end

    desc 'Create order_array.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'createOrderArray',
      params: V01::Entities::OrderArray.documentation.except(:id, :orders).deep_merge(
        name: { required: true },
        base_date: { required: true },
        length: { required: true }
      ),
      entity: V01::Entities::OrderArray
    post do
      order_array = current_customer.order_arrays.build(order_array_params)
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc 'Update order_array.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'updateOrderArray',
      params: V01::Entities::OrderArray.documentation.except(:id, :orders),
      entity: V01::Entities::OrderArray
    params do
      requires :id, type: Integer
    end
    put ':id' do
      order_array = current_customer.order_arrays.find(params[:id])
      order_array.update! order_array_params
      present order_array, with: V01::Entities::OrderArray
    end

    desc 'Delete order_array.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'deleteOrderArray'
    params do
      requires :id, type: Integer
    end
    delete ':id' do
      current_customer.order_arrays.find(params[:id]).destroy
    end

    desc 'Delete multiple order_arrays.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'deleteOrderArrays'
    params do
      requires :ids, type: Array[Integer], coerce_with: CoerceArrayInteger
    end
    delete do
      OrderArray.transaction do
        current_customer.order_arrays.select{ |order_array| params[:ids].include?(order_array.id) }.each(&:destroy)
      end
    end

    desc 'Clone the order_array.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'cloneOrderArray',
      entity: V01::Entities::OrderArray
    params do
      requires :id, type: Integer
    end
    patch ':id/duplicate' do
      order_array = current_customer.order_arrays.find(params[:id])
      order_array = order_array.amoeba_dup
      order_array.save!
      present order_array, with: V01::Entities::OrderArray
    end

    desc 'Orders mass assignment.',
      detail: 'Only available if "order array" option is active for current customer.',
      nickname: 'massAssignmentOrder'
    params do
      requires :id, type: Integer
    end
    patch ':id' do
      if params[:orders]
        order_array = current_customer.order_arrays.find(params[:id])
        orders = Hash[order_array.orders.load.map{ |order| [order.id, order] }]
        products = Hash[current_customer.products.collect{ |product| [product.id, product] }]
        params[:orders].each{ |id, order|
          id = Integer(id)
          order[:product_ids] ||= []
          if orders.key?(id)
            # Workaround for multiple values need add values and not affect
            orders[id].products.clear
            orders[id].products += order[:product_ids].map{ |product_id| products[Integer(product_id)] }.compact
          end
        }
        order_array.save!
      end
      return
    end
  end
end
