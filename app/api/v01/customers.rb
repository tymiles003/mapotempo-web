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
require 'tomtom'

class V01::Customers < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      p = ActionController::Parameters.new(params)
      p = p[:customer] if p.key?(:customer)
      if @current_user.admin?
        p.permit(:ref, :name, :end_subscription, :max_vehicles, :take_over, :print_planning_annotating, :print_header, :enable_tomtom, :enable_masternaut, :enable_alyacom, :tomtom_account, :tomtom_user, :tomtom_password, :masternaut_user, :masternaut_password, :router_id, :enable_orders, :test, :alyacom_association, :optimization_cluster_size, :optimization_time, :optimization_soft_upper_bound, :profile_id, :default_country, :reseller_id, :print_stop_time, :speed_multiplicator, :enable_references, :enable_multi_visits)
      else
        p.permit(:take_over, :print_planning_annotating, :print_header, :tomtom_account, :tomtom_user, :tomtom_password, :masternaut_user, :masternaut_password, :router_id, :alyacom_association, :default_country, :print_stop_time, :speed_multiplicator)
      end
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'
  end

  resource :customers do
    desc 'Fetch customer.',
      nickname: 'getCustomer',
      is_array: true,
      entity: V01::Entities::Customer
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      if @current_user.admin?
        present current_customer(params[:id]), with: V01::Entities::Customer
      elsif @current_user.customer.id == params[:id].to_i || (@current_user.customer.ref && 'ref:' + @current_user.customer.ref == params[:id])
        present @current_user.customer, with: V01::Entities::Customer
      else
        status 404
      end
    end

    desc 'Update customer.',
      nickname: 'updateCustomer',
      params: V01::Entities::Customer.documentation.except(
        :id,
        :store_ids,
        :job_destination_geocoding_id,
        :job_store_geocoding_id,
        :job_optimizer_id
      ),
      entity: V01::Entities::Customer
    params do
      requires :id, type: String, desc: ID_DESC
    end
    put ':id' do
      current_customer(params[:id])
      @current_customer.update(customer_params)
      @current_customer.save!
      present @current_customer, with: V01::Entities::Customer
    end

    desc 'Create customer.',
      detail: 'Only available with an admin api_key.',
      nickname: 'createCustomer',
      params: V01::Entities::Customer.documentation.except(
        :id,
        :store_ids,
        :job_destination_geocoding_id,
        :job_store_geocoding_id,
        :job_optimizer_id
      ).deep_merge(
        name: { required: true },
        default_country: { required: true },
        router_id: { required: true },
        profile_id: { required: true }
      ),
      entity: V01::Entities::Customer
    post do
      if @current_user.admin?
        customer = @current_user.reseller.customers.build(customer_params)
        @current_user.reseller.save!
        present customer, with: V01::Entities::Customer
      end
    end

    desc 'Delete customer.',
      detail: 'Only available with an admin api_key.',
      nickname: 'deleteCustomer'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    delete ':id' do
      if @current_user.admin?
        id = ParseIdsRefs.read(params[:id])
        @current_user.reseller.customers.where(id).first!.destroy
      end
    end

    desc 'Return a job',
      detail: 'Return asynchronous job (like geocoding, optimizer) currently runned for the customer.',
      nickname: 'getJob'
    params do
      requires :id, type: String, desc: ID_DESC
      requires :job_id, type: Integer
    end
    get ':id/job/:job_id' do
      current_customer(params[:id])
      if @current_customer.job_optimizer && @current_customer.job_optimizer_id = params[:job_id]
        @current_customer.job_optimizer
      elsif @current_customer.job_destination_geocoding && @current_customer.job_destination_geocoding_id = params[:job_id]
        @current_customer.job_destination_geocoding
      elsif @current_customer.job_store_geocoding && @current_customer.job_store_geocoding_id = params[:job_id]
        @current_customer.job_store_geocoding
      end
    end

    desc 'Cancel job',
      detail: 'Cancel asynchronous job (like geocoding, optimizer) currently runned for the customer.',
      nickname: 'deleteJob'
    params do
      requires :id, type: String, desc: ID_DESC
      requires :job_id, type: Integer
    end
    delete ':id/job/:job_id' do
      current_customer(params[:id])
      if @current_customer.job_optimizer && @current_customer.job_optimizer_id = params[:job_id]
        @current_customer.job_optimizer.destroy
      elsif @current_customer.job_destination_geocoding && @current_customer.job_destination_geocoding_id = params[:job_id]
        @current_customer.job_destination_geocoding.destroy
      elsif @current_customer.job_store_geocoding && @current_customer.job_store_geocoding_id = params[:job_id]
        @current_customer.job_store_geocoding.destroy
      end
    end

    desc 'Fetch tomtom ids.',
      detail: 'Get tomtom webfleet device ids if they are set for this customer.',
      nickname: 'getTomtomIds'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id/tomtom_ids' do
      current_customer(params[:id])
      Hash[Tomtom.fetch_devices(@current_customer).collect{ |tomtom|
        [tomtom[:objectUid], tomtom[:objectName]]
      }]
    end
  end
end
