Rails.configuration.middleware.use Browser::Middleware do
  redirect_to unsupported_browser_path(browser: :ie) if browser.ie?
  redirect_to unsupported_browser_path(browser: :modern) if !browser.modern?
end
