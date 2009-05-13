require 'test_helper'

class GovernmentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:governments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create government" do
    assert_difference('Government.count') do
      post :create, :government => { }
    end

    assert_redirected_to government_path(assigns(:government))
  end

  test "should show government" do
    get :show, :id => governments(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => governments(:one).id
    assert_response :success
  end

  test "should update government" do
    put :update, :id => governments(:one).id, :government => { }
    assert_redirected_to government_path(assigns(:government))
  end

  test "should destroy government" do
    assert_difference('Government.count', -1) do
      delete :destroy, :id => governments(:one).id
    end

    assert_redirected_to governments_path
  end
end
