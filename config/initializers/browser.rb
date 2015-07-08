Rails.configuration.middleware.use Browser::Middleware do
  if not request.env['PATH_INFO'].start_with?('/api/')
    redirect_to unsupported_browser_path(browser: :modern) if !browser.modern?
  end
end
