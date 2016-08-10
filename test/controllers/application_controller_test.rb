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

  test 'should return an error with flash[:error]' do
    users(:user_one).customer.update! end_subscription: (Time.now - 30.days)
    sign_in users(:user_one)
    get :index
    assert_not_nil flash.now[:error]
  end
end
