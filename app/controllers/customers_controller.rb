# Copyright © Mapotempo, 2013-2014
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
class CustomersController < ApplicationController
  load_and_authorize_resource

  before_action :set_customer, only: [:edit, :update, :delete_vehicle]
  before_action :clear_customer_params, only: [:create, :update]

  helper_method :tomtom_default_password

  def index
    @customers = current_user.reseller.customers.order(:name)
  end

  def new
    @customer = current_user.reseller.customers.build
  end

  def edit
  end

  def create
    @customer = current_user.reseller.customers.build(customer_params)
    @customer.speed_multiplicator /= 100 if @customer.speed_multiplicator

    respond_to do |format|
      if @customer.save && @customer.update(customer_params) && @customer.save
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.created', model: @customer.class.model_name.human) }
      else
        if @customer.speed_multiplicator
          @customer.speed_multiplicator = (@customer.speed_multiplicator * 100).to_i
        end
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      p = customer_params
      @customer.assign_attributes(p)
      @customer.speed_multiplicator /= 100 if @customer.speed_multiplicator
      if @customer.save
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.updated', model: @customer.class.model_name.human) }
      else
        if @customer.speed_multiplicator
          @customer.speed_multiplicator = (@customer.speed_multiplicator * 100).to_i
        end
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_url }
    end
  end

  def delete_vehicle
    if current_user.admin?
      respond_to do |format|
        vehicle = @customer.vehicles.find(params[:vehicle_id])
        if vehicle.destroy
          format.html { redirect_to edit_customer_path(@customer) }
        else
          flash[:error] = vehicle.errors.full_messages
          format.html { redirect_to edit_customer_path(@customer) }
        end
      end
    else
      error! 'Forbidden', 403
    end
  end

  def destroy_multiple
    Customer.transaction do
      if params['customers'].keys
        ids = params['customers'].keys.collect{ |i| Integer(i) }
        current_user.reseller.customers.select{ |customer| ids.include?(customer.id) }.each(&:destroy)
      end
      respond_to do |format|
        format.html { redirect_to customers_url }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_customer
    @customer = if current_user.admin?
      current_user.reseller.customers.find(params[:id] || params[:customer_id])
    else
      current_user.customer
    end
    if @customer.speed_multiplicator
      @customer.speed_multiplicator = (@customer.speed_multiplicator * 100).to_i
    end
  end

  def tomtom_default_password
    '97!8Or748trp'
  end

  def clear_customer_params
    params[:customer].delete(:tomtom_password) if params[:customer][:tomtom_password] == tomtom_default_password # Delete default password displayed in form
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def customer_params
    if current_user.admin?
      params.require(:customer).permit(:ref, :name, :end_subscription, :max_vehicles, :take_over, :print_planning_annotating, :print_header, :enable_tomtom, :enable_masternaut, :enable_alyacom, :tomtom_account, :tomtom_user, :tomtom_password, :masternaut_user, :masternaut_password, :router_id, :speed_multiplicator, :enable_orders, :test, :alyacom_association, :optimization_cluster_size, :optimization_time, :optimization_soft_upper_bound, :profile_id, :default_country, :enable_multi_vehicle_usage_sets, :print_stop_time, :enable_references, :enable_multi_visits)
    else
      params.require(:customer).permit(:take_over, :print_planning_annotating, :print_header, :tomtom_account, :tomtom_user, :tomtom_password, :masternaut_user, :masternaut_password, :router_id, :speed_multiplicator, :alyacom_association, :default_country, :print_stop_time)
    end
  end
end
