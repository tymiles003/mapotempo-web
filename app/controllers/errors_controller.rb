class ErrorsController < ApplicationController
  layout 'full_page'

  def show
    respond_to do |format|
      format.html { render 'errors/show', locals: { status: status_code } }
      format.json { render json: { error: t('errors.management.status.explanation.default') }, status: status_code }
      format.all { render body: nil, status: status_code }
    end
  end

  private

  def status_code
    params[:code] || 500
  end
end
