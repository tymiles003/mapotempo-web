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

  test "should get index in excel" do
    get :index, format: :excel
    assert_response :success
    assert_not_nil assigns(:destinations)
    assert_equal "destination_one;Rue des Lilas;MyString;33200;Bordeau;49.1857;-0.3735;1;10:00;11:00;MyString;tag1", response.body.split("\n")[2]
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create destination" do
    assert_difference('Destination.count') do
      post :create, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, customer: @destination.customer, detail: @destination.detail, comment: @destination.comment, tag_ids: [tags(:tag_one).id] }
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

  test "should update destination tags" do
    patch :update, id: @destination, destination: { tag_ids: [tags(:tag_two).id] }
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
    patch :geocode, format: :json, destination: { city: @destination.city, name: @destination.name, postalcode: @destination.postalcode, street: @destination.street }
    assert_response :success
  end

  test "should not geocode" do
    patch :geocode, format: :json, destination: { name: @destination.name }
    assert_response :unprocessable_entity
  end

  test "should geocode reverse" do
    patch :geocode_reverse, format: :json, id: @destination.id, destination: { lat: 45.0, lon: 0.0 }
    assert_response :success
  end

  test "should not geocode reverse" do
    patch :geocode_reverse, format: :json, id: @destination.id, destination: { }
    assert_response :unprocessable_entity
  end

  test "should geocode complete" do
    patch :geocode_complete, format: :json, id: @destination.id, destination: { city: "Montpellier", street: "Rue de la Chaînerais" }
    assert_response :success
  end

  test "should clear" do
    delete :clear
    assert_redirected_to destinations_path
  end

  test "should import" do
    get :import
    assert_response :success
  end

  test "should upload" do
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join("test/fixtures/files/import_one.csv")),
    })
    file.original_filename = "import_one.csv"

    assert_difference('Destination.count') do
      assert_difference('Stop.count', 1 + 3 + 3) do
        post :upload, destinations_import_model: { replace: false, file: file }
      end
    end

    assert_redirected_to destinations_path
  end

  test "should not upload" do
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join("test/fixtures/files/import_invalid.csv")),
    })
    file.original_filename = "import_invalid.csv"

    assert_difference('Destination.count', 0) do
      post :upload, destinations_import_model: { replace: false, file: file }
    end

    assert_template :import
    assert_not_nil flash[:error]
  end
end
