require 'simplecov'
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

#WebMock.allow_net_connect!
WebMock.disable_net_connect!

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def setup
    uri_template = Addressable::Template.new('services.gisgraphy.com/street/streetsearch{?format}{&other*}')
    @stub_gisgraphy = stub_request(:get, uri_template).to_return(:status => 503, :body => '503 Service Temporarily Unavailable', :headers => {})

    uri_template = Addressable::Template.new('gpp3-wxs.ign.fr/{api_key}/geoportail/ols')
    @stub_GeocodeRequest = stub_request(:post, uri_template).with { |request|
      request.body.include?("methodName='GeocodeRequest'")
    }.to_return(File.new(File.expand_path('../', __FILE__) + '/fixtures/gpp3-wxs.ign.fr/GeocodeRequest.xml').read)

    uri_template = Addressable::Template.new('gpp3-wxs.ign.fr/{api_key}/geoportail/ols')
    @stub_LocationUtilityService = stub_request(:post, uri_template).with { |request|
      request.body.include?("methodName='LocationUtilityService'")
    }.to_return(File.new(File.expand_path('../', __FILE__) + '/fixtures/gpp3-wxs.ign.fr/LocationUtilityService.xml').read)
  end

  def teardown
    remove_request_stub(@stub_gisgraphy)
    remove_request_stub(@stub_GeocodeRequest)
    remove_request_stub(@stub_LocationUtilityService)
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
end
