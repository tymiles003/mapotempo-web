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

  # Handle exceptions
  rescue_from StandardError, with: :server_error
  rescue_from ActionController::InvalidAuthenticityToken, with: :server_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_error
  rescue_from ActionController::RoutingError, with: :not_found_error
  rescue_from AbstractController::ActionNotFound, with: :not_found_error
  rescue_from ActionController::UnknownController, with: :not_found_error

  layout :layout_by_resource

  before_action :api_key?, :load_vehicles
  before_action :set_locale
  before_action :customer_payment_period, if: :current_user
  around_action :set_time_zone, if: :current_user

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  def api_key?
    if params['api_key']
      if (user = User.find_by(api_key: params['api_key']))
        warden.set_user(user, run_callbacks: false)
      else
        redirect_to new_user_session_path, alert: t('web.key_not_found')
      end
    end
  end

  def load_vehicles
    if current_user && !current_user.admin?
      @vehicle_usage_sets = current_user.customer.vehicle_usage_sets.includes([:vehicle_usages, {vehicle_usages: [:vehicle]}])
    end
  end

  def append_info_to_payload(payload)
    super
    # More info for Lograge
    payload[:customer_id] = current_user && current_user.customer && current_user.customer.id
  end

  protected

  def set_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale
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

  def customer_payment_period
    if current_user.customer
      customer = current_user.customer
      @unsubscribed = customer.end_subscription && Time.now >= customer.end_subscription
      if @unsubscribed
        flash.now[:error] = I18n.t('subscribe.expiration_date_over', scope: :all) + I18n.l((customer.end_subscription - 1.second), format: :long)
      end
    end
  end

  def not_found_error(exception)
    # Display in logger
    Rails.logger.fatal(exception.class.to_s + ' : ' + exception.to_s)
    Rails.logger.fatal(exception.backtrace.join("\n"))

    respond_to do |format|
      format.html { render 'errors/show', layout: 'full_page', locals: { status: 404 }, status: 404 }
      format.json { render json: { error: t('errors.management.status.explanation.404') }, status: :not_found }
      format.all { render body: nil, status: :not_found }
    end

    # Raise error in development for debugging and in production for sentry
    raise
  end

  def server_error(exception)
    # Display in logger
    Rails.logger.fatal(exception.class.to_s + ' : ' + exception.to_s)
    Rails.logger.fatal(exception.backtrace.join("\n"))

    respond_to do |format|
      format.html { render 'errors/show', layout: 'full_page', locals: { status: 500 }, status: 500 }
      format.json { render json: { error: t('errors.management.status.explanation.default') }, status: :internal_server_error }
      format.all { render body: nil, status: :internal_server_error }
    end

    # Raise error in development for debugging and in production for sentry
    raise
  end

end
