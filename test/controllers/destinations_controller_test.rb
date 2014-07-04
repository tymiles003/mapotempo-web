require 'test_helper'

class DestinationsControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @destination = destinations(:destination_one)
    sign_in users(:user_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:destinations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create destination" do
    assert_difference('Destination.count') do
      post :create, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, customer: @destination.customer, detail: @destination.detail, comment: @destination.comment }
    end

    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test "should not create destination" do
    assert_difference('Destination.count', 0) do
      post :create, destination: { name: "" }
    end

    assert_template :new
    destination = assigns(:destination)
    assert destination.errors.any?
  end

  test "should get edit" do
    get :edit, id: @destination
    assert_response :success
  end

  test "should update destination" do
    patch :update, id: @destination, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, customer: @destination.customer, detail: @destination.detail, comment: @destination.comment }
    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test "should not update destination" do
    patch :update, id: @destination, destination: { name: "", customer: @destination.customer }

    assert_template :edit
    destination = assigns(:destination)
    assert destination.errors.any?
  end

  test "should destroy destination" do
    assert_difference('Destination.count', -1) do
      delete :destroy, id: @destination
    end

    assert_redirected_to destinations_path
  end

  test "should geocode" do
    patch :geocode_reverse, format: :json, id: @destination.id, destination: { city: "Montpellier", street: "Rue de la Chaînerais" }
    assert_response :success
  end

  test "should geocode reverse" do
    patch :geocode_reverse, format: :json, id: @destination.id, destination: { lat: 45.0, lon: 0.0 }
    assert_response :success
  end

  test "should geocode complete" do
    patch :geocode_reverse, format: :json, id: @destination.id, destination: { city: "Montpellier", street: "Rue de la Chaînerais" }
    assert_response :success
  end

  test "should show import" do
    get :import
    assert_response :success
  end

  test "should upload" do
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join("test/fixtures/files/import_one.csv")),
      original_filename: "import_one.csv"
    })
    file.original_filename = "import_one.csv"
    post :upload, destinations_import_model: { replace: true, file: file }
    assert_redirected_to destinations_path
  end
end
