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
class Admin::UsersController < ApplicationController
  load_and_authorize_resource
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.joins(:customer).where(customers: {reseller_id: current_user.reseller_id})
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
    @customers = current_user.reseller.customers.order(:name)
    @user.customer = @customers.select{ |c| c.id == Integer(params[:customer]) }.first if params.key?(:customer)
  end

  # GET /users/1/edit
  def edit
    @customers = current_user.reseller.customers.order(:name)
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to edit_customer_path(@user.customer), notice: t('activerecord.successful.messages.created', model: @user.class.model_name.human) }
        format.json { render action: 'show', status: :created, location: @user }
      else
        @customers = current_user.reseller.customers.order(:name)
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to edit_customer_path(@user.customer), notice: t('activerecord.successful.messages.updated', model: @user.class.model_name.human) }
        format.json { head :no_content }
      else
        @customers = current_user.reseller.customers.order(:name)
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    if !@user.admin?
      @user.destroy
      respond_to do |format|
        format.html { redirect_to admin_users_path }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to action: 'edit', status: :unprocessable_entity }
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def destroy_multiple
    User.transaction do
      ids = params['users'].keys.collect{ |i| Integer(i) }
      User.find(ids).each(&:destroy)
      respond_to do |format|
        format.html { redirect_to admin_users_path }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    User.joins(:customer).where(id: params[:id] || params[:user_id], customers: {reseller_id: current_user.reseller_id}).first!
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:email, :customer_id, :layer_id, :password, :password_confirmation)
  end
end
