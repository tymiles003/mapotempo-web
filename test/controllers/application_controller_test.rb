require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase

  ApplicationController.class_eval do
    def index
      render nothing: true
    end
  end

  Rails.application.routes.disable_clear_and_finalize = true

  Rails.application.routes.draw do
   get 'index' => 'application#index'
  end

  test 'should set user from api key without updating sign in at' do
    users(:user_one).update(current_sign_in_at: Time.new(2000), last_sign_in_at: Time.new(2000))

    get :index, api_key: 'testkey1'
    assert_equal [Time.new(2000)], users(:user_one).reload.attributes.slice('current_sign_in_at', 'last_sign_in_at').values.uniq
  end

  test 'should return an error with flash[:error]' do
    users(:user_one).customer.update! end_subscription: (Time.now - 30.days)
    sign_in users(:user_one)
    get :index
    assert_not_nil flash.now[:error]
  end
end
