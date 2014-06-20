module LinkBack
  extend ActiveSupport::Concern

  included do
    after_filter "save_link_back", only: [:new, :edit]
  end

  def save_link_back
    # session[:previous_url] is a Rails built-in variable to save last url.
    session[:link_back] ||= URI(request.referer).path
  end

  def link_back
    session.delete(:link_back)
  end
end
