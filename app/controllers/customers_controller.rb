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
  load_and_authorize_resource :except => [:create]
  before_action :set_customer, only: [:edit, :update]

  def index
    @customers = Customer.order(:name)
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    # Can set max_vehicles on creation
    @customer = Customer.new(customer_params.except('max_vehicles'))

    respond_to do |format|
      if @customer.save && @customer.update(customer_params) && @customer.save
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.created', model: @customer.class.model_name.human) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.updated', model: @customer.class.model_name.human) }
      else
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      if current_user.admin?
        params.require(:customer).permit(:name, :end_subscription, :max_vehicles, :take_over, :print_planning_annotating, :print_header, :tomtom_account, :tomtom_user, :tomtom_password, :masternaut_account, :masternaut_user, :masternaut_password, :router_id, :enable_orders, :test, :alyacom_association)
      else
        params.require(:customer).permit(:take_over, :print_planning_annotating, :print_header, :tomtom_account, :tomtom_user, :tomtom_password, :masternaut_account, :masternaut_user, :masternaut_password, :router_id, :alyacom_association)
      end
    end
end
