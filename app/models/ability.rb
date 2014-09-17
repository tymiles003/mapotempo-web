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

class Ability
  include CanCan::Ability
  def initialize(user)
    if user
      if user.admin?
        can :manage, :all
      else
        can [:edit, :update], User, :id => user.id
        can [:edit_settings, :update_settings], User, :id => user.id
        can [:edit, :update], Customer, :id => user.customer.id
        can [:stop_job_matrix, :stop_job_optimizer, :stop_job_geocoding], Customer
        can [:index, :edit, :update], Vehicle, :customer_id => user.customer.id
        can :manage, Tag, :customer_id => user.customer.id
        can :manage, Destination, :id => user.customer.store_id
        can :manage, Destination, :customer_id => user.customer.id
        can :manage, Zoning, :customer_id => user.customer.id
        if not user.customer.end_subscription or user.customer.end_subscription > Time.now
          can :manage, Planning, :customer_id => user.customer.id
        end
        can :manage, Route, :planning => {:customer_id => user.customer.id}
      end
    end
  end
end

