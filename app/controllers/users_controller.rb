# Copyright © Mapotempo, 2013-2016
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
class UsersController < ApplicationController
  load_and_authorize_resource

  before_action :set_customer_and_user, except: [:password, :set_password]
  before_action :set_customer_and_user_from_token, only: [:password, :set_password]

  def edit; end

  def update
    if @user.update user_params
      redirect_to_default
    else
      render action: :edit
    end
  end

  def password
    if current_user != @user
      sign_out :user
      sign_in @user, bypass_sign_in: true
    end
  end

  def set_password
    if @user.update user_password_params
      @user.confirm! if !@user.confirmed?
      sign_in @user, bypass_sign_in: true
      redirect_to_default
    else
      render action: :password
    end
  end

  private

  def redirect_to_default
    redirect_to !params[:url].blank? ? params[:url] : [:edit, @customer], notice: t("users.#{action_name}.success")
  end

  def set_customer_and_user
    @customer = current_user.customer
    @user = current_user.customer.users.find params[:id]
  end

  def set_customer_and_user_from_token
    @customer = Customer.find params[:customer_id]
    @user = @customer.users.find_by confirmation_token: params[:token]
  end

  def user_password_params
    params.require(:user).permit :password, :password_confirmation
  end

  def user_params
    params.require(:user).permit :layer_id, :url_click2call, :time_zone
  end
end
