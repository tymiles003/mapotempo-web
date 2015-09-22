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
class V01::Users < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      p = ActionController::Parameters.new(params)
      p = p[:user] if p.key?(:user)
      if @current_user.admin?
        p.permit(:email, :password, :customer_id, :layer_id)
      else
        p.permit(:layer_id)
      end
    end
  end

  resource :users do
    desc 'Fetch customer\'s users.',
      nickname: 'getUsers',
      is_array: true,
      entity: V01::Entities::User
    get do
      present current_customer.users.load, with: V01::Entities::User
    end

    desc 'Fetch user.',
      nickname: 'getUser',
      entity: V01::Entities::User
    params do
      requires :id, type: Integer
    end
    get ':id' do
      if @current_user.admin?
        present User.find(params[:id]), with: V01::Entities::User
      else
        present current_customer.users.find(params[:id]), with: V01::Entities::User
      end
    end

    desc 'Create user.',
      nickname: 'createUser',
      params: V01::Entities::User.documentation.except(:id).merge(
        email: { required: true },
        password: { required: true },
        customer_id: { required: true },
        layer_id: { required: true }
      ),
      entity: V01::Entities::User
    post do
      if @current_user.admin?
        customer = Customer.find(params[:customer_id])
        user = customer.users.build(user_params)
        user.password_confirmation = user.password
        user.save!
        present user, with: V01::Entities::User
      else
        error! 'Forbidden', 403
      end
    end

    desc 'Update user.',
      nickname: 'updateUser',
      params: V01::Entities::User.documentation.except(:id),
      entity: V01::Entities::User
    params do
      requires :id, type: Integer
    end
    put ':id' do
      user = @current_user.admin? ? User.find(params[:id]) : @current_user
      user.update(user_params)
      user.save!
      present user, with: V01::Entities::User
    end

    desc 'Delete user.',
      nickname: 'deleteUser'
    params do
      requires :id, type: Integer
    end
    delete ':id' do
      if @current_user.admin?
        user = User.find(params[:id])
        user.destroy!
      else
        error! 'Forbidden', 403
      end
    end

    desc 'Delete multiple users.',
      nickname: 'deleteUsers'
    params do
      requires :ids, type: Array[Integer], coerce_with: V01::CoerceArrayInteger
    end
    delete do
      if @current_user.admin?
        User.transaction do
          User.select{ |user| params[:ids].include?(user.id) }.each(&:destroy)
        end
      else
        error! 'Forbidden', 403
      end
    end

  end
end
