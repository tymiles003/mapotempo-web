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
    @customers = Customer.all
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    @customer = Customer.new(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.created', model: @customer.class.model_name.human) }
        format.json { render action: 'show', status: :created, location: @customer }
      else
        format.html { render action: 'new' }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.updated', model: @customer.class.model_name.human) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_url }
      format.json { head :no_content }
    end
  end

  def stop_job_matrix
    if current_user.customer.job_matrix
      current_user.customer.job_matrix.destroy
    end
    render json: {}
  end

  def stop_job_optimizer
    if current_user.customer.job_optimizer
      current_user.customer.job_optimizer.destroy
    end
    render json: {}
  end

  def stop_job_geocoding
    if current_user.customer.job_geocoding
      current_user.customer.job_geocoding.destroy
    end
    render json: {}
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      if current_user.admin?
        params.require(:customer).permit(:name, :end_subscription, :max_vehicles, :take_over)
      else
        params.require(:customer).permit(:take_over)
      end
    end
end
