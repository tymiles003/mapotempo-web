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
class V01::Products < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      p = ActionController::Parameters.new(params)
      p = p[:product] if p.key?(:product)
      p.permit(:name, :code)
    end
  end

  resource :products do
    desc 'Fetch customer\'s products.',
      nickname: 'getProducts',
      is_array: true,
      entity: V01::Entities::Product
    params do
      optional :ids, type: Array[Integer], desc: 'Select returned products by id.', coerce_with: V01::CoerceArrayInteger
    end
    get do
      products = if params.key?(:ids)
        current_customer.products.select{ |product| params[:ids].include?(product.id) }
      else
        current_customer.products.load
      end
      present products, with: V01::Entities::Product
    end

    desc 'Fetch product.',
      nickname: 'getProduct',
      entity: V01::Entities::Product
    params do
      requires :id, type: Integer
    end
    get ':id' do
      present current_customer.products.find(params[:id]), with: V01::Entities::Product
    end

    desc 'Create product.',
      nickname: 'createProduct',
      params: V01::Entities::Product.documentation.except(:id).merge(
        code: { required: true },
        name: { required: true }
      ),
      entity: V01::Entities::Product
    post do
      product = current_customer.products.build(product_params)
      product.save!
      present product, with: V01::Entities::Product
    end

    desc 'Update product.',
      nickname: 'updateProduct',
      params: V01::Entities::Product.documentation.except(:id),
      entity: V01::Entities::Product
    params do
      requires :id, type: Integer
    end
    put ':id' do
      product = current_customer.products.find(params[:id])
      product.update(product_params)
      product.save!
      present product, with: V01::Entities::Product
    end

    desc 'Delete product.',
      nickname: 'deleteProduct'
    params do
      requires :id, type: Integer
    end
    delete ':id' do
      current_customer.products.find(params[:id]).destroy
    end

    desc 'Delete multiple products.',
      nickname: 'deleteProducts'
    params do
      requires :ids, type: Array[Integer], coerce_with: V01::CoerceArrayInteger
    end
    delete do
      Product.transaction do
        current_customer.products.select{ |product| params[:ids].include?(product.id) }.each(&:destroy)
      end
    end
  end
end
