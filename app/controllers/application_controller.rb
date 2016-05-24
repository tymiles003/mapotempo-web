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
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout :layout_by_resource

  include HttpAcceptLanguage::AutoLocale

  before_action :api_key?, :load_vehicles, :set_locale

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  def api_key?
    if params['api_key']
      warden.set_user(User.find_by(api_key: params['api_key']), run_callbacks: false)
    end
  end

  def load_vehicles
    if current_user && !current_user.admin?
      @vehicle_usage_sets = current_user.customer.vehicle_usage_sets.includes([:vehicle_usages, { :vehicle_usages => [:vehicle] }])
    end
  end

  def append_info_to_payload(payload)
    super
    # More info for Lograge
    payload[:customer_id] = current_user && current_user.customer && current_user.customer.id
  end

  protected

  def set_locale
    Time.zone = current_user.time_zone if current_user
    I18n.locale = http_accept_language.compatible_language_from %w(en fr)
  end

  def devise_parameter_sanitizer
    if resource_class == User
      UserParameterSanitizer.new(User, :user, params)
    else
      super
    end
  end

  def layout_by_resource
    if devise_controller?
      'registration'
    else
      'application'
    end
  end
end
