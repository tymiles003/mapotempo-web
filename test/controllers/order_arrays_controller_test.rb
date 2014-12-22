require 'test_helper'

require 'rexml/document'
include REXML

class OrderArraysControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @order_array = order_arrays(:order_array_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:order_arrays)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create order_array" do
    assert_difference('OrderArray.count') do
      post :create, order_array: { name: 'test', length: 'week', base_date: '10/10/2014' }
    end

    assert_redirected_to edit_order_array_path(assigns(:order_array))
  end

  test "should not create order_array" do
    assert_difference('OrderArray.count', 0) do
      post :create, order_array: { name: "" }
    end

    assert_template :new
    order_array = assigns(:order_array)
    assert order_array.errors.any?
  end

  test "should show order_array" do
    get :show, id: @order_array
    assert_response :success
  end

  test "should show order_array as excel" do
    get :show, id: @order_array, format: :excel
    assert_response :success
  end

  test "should show order_array as csv" do
    get :show, id: @order_array, format: :csv
    assert_response :success
    assert_equal ',,,,,,a,unaffected_one,MyString,MyString,MyString,MyString,1.5,1.5,MyString,00:01:00,1,,10:00,11:00,tag1,"","",""', response.body.split("\n")[1]
    assert_equal 'vehicle_one,route_one,2,,00:00,1.5,c,destination_two,MyString,MyString,MyString,MyString,1.5,1.5,MyString,,3,1,10:00,11:00,tag1,"","",""', response.body.split("\n").select{ |l| l.include?('vehicle_one') }[2]
  end

  test "should get edit" do
    get :edit, id: @order_array
    assert_response :success
  end

  test "should update order_array" do
    patch :update, id: @order_array, order_array: { name: @order_array.name, base_date: Date.new(2018,10,10) }
    assert_redirected_to edit_order_array_path(assigns(:order_array))
  end

  test "should not update order_array" do
    patch :update, id: @order_array, order_array: { name: "" }

    assert_template :edit
    order_array = assigns(:order_array)
    assert order_array.errors.any?
  end

  test "should destroy order_array" do
    assert_difference('OrderArray.count', -1) do
      delete :destroy, id: @order_array
    end

    assert_redirected_to order_arrays_path
  end

  test "should duplicate" do
    assert_difference('OrderArray.count') do
      patch :duplicate, order_array_id: @order_array
    end

    assert_redirected_to edit_order_array_path(assigns(:order_array))
  end
end
