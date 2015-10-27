require 'test_helper'

class DestinationsControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @destination = destinations(:destination_one)
    sign_in users(:user_one)
  end

  def around
    Osrm.stub_any_instance(:compute, [1000, 60, 'trace']) do
      yield
    end
  end

  test 'user can only view destinations from its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :manage, destinations(:destination_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, destinations(:destination_one)
    sign_in users(:user_three)
    get :edit, id: @destination
    assert_response :redirect
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:destinations)
    assert_valid response
  end

  test 'should get index in excel' do
    get :index, format: :excel
    assert_response :success
    assert_not_nil assigns(:destinations)
    assert_equal 'b;destination_one;Rue des Lilas;MyString;33200;Bordeau;;49.1857;-0.3735;;;00:05:33;1;10:00;11:00;MyString;tag1', response.body.split("\n").find{ |l| l[0] == 'b' }
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_valid response
  end

  test 'should create destination' do
    assert_difference('Stop.count', 1) do
      assert_difference('Destination.count') do
        post :create, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, detail: @destination.detail, comment: @destination.comment, phone_number: @destination.phone_number, tag_ids: [tags(:tag_one).id] }
      end
    end

    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test 'should create destination and touch planning' do
    d = Planning.find_by(name: 'planning1')
    d.tags = []
    d.save!
    assert_difference('Stop.count', 1) do
      assert_difference('Destination.count') do
        post :create, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, detail: @destination.detail, comment: @destination.comment, phone_number: @destination.phone_number }
      end
    end

    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test 'should not create destination' do
    assert_difference('Destination.count', 0) do
      post :create, destination: { name: '' }
    end

    assert_template :new
    destination = assigns(:destination)
    assert destination.errors.any?
    assert_valid response
  end

  test 'should get edit' do
    get :edit, id: @destination
    assert_response :success
    assert_valid response
  end

  test 'should update destination' do
    patch :update, id: @destination, destination: { city: @destination.city, close: @destination.close, lat: @destination.lat, lng: @destination.lng, name: @destination.name, open: @destination.open, postalcode: @destination.postalcode, quantity: @destination.quantity, street: @destination.street, detail: @destination.detail, comment: @destination.comment, phone_number: @destination.phone_number }
    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test 'should update destination tags' do
    patch :update, id: @destination, destination: { tag_ids: [tags(:tag_two).id] }
    assert_redirected_to edit_destination_path(assigns(:destination))
  end

  test 'should not update destination' do
    patch :update, id: @destination, destination: { name: '' }

    assert_template :edit
    destination = assigns(:destination)
    assert destination.errors.any?
    assert_valid response
  end

  test 'should destroy destination' do
    assert_difference('Destination.count', -1) do
      delete :destroy, id: @destination
    end

    assert_redirected_to destinations_path
  end

  test 'should clear' do
    delete :clear
    assert_redirected_to destinations_path
  end

  test 'should show import_template' do
    get :import_template, format: :csv
    assert_response :success
  end

  test 'should import' do
    get :import
    assert_response :success
    assert_valid response
  end

  test 'should upload' do
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_one.csv')),
    })
    file.original_filename = 'import_destinations_one.csv'

    destinations_count = @destination.customer.destinations.count
    plannings_count = @destination.customer.plannings.select{ |planning| planning.tags == [tags(:tag_one)] }.count
    import_count = 1
    rest_count = 1

    assert_difference('Destination.count') do
      assert_difference('Stop.count', (destinations_count + import_count + rest_count) + (import_count + rest_count) * plannings_count) do
        assert_difference('Planning.count') do
          post :upload, destinations_import: { replace: false, file: file }
        end
      end
    end

    assert_redirected_to destinations_path
  end

  test 'should not upload' do
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join('test/fixtures/files/import_invalid.csv')),
    })
    file.original_filename = 'import_invalid.csv'

    assert_difference('Destination.count', 0) do
      post :upload, destinations_import: { replace: false, file: file }
    end

    assert_template :import
    assert_not_nil flash[:error]
    assert_valid response
  end
end
