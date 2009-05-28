require 'test_helper'

class BranchesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:branches)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create branch" do
    assert_difference('Branch.count') do
      post :create, :branch => { }
    end

    assert_redirected_to branch_path(assigns(:branch))
  end

  test "should show branch" do
    get :show, :id => branches(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => branches(:one).to_param
    assert_response :success
  end

  test "should update branch" do
    put :update, :id => branches(:one).to_param, :branch => { }
    assert_redirected_to branch_path(assigns(:branch))
  end

  test "should destroy branch" do
    assert_difference('Branch.count', -1) do
      delete :destroy, :id => branches(:one).to_param
    end

    assert_redirected_to branches_path
  end
end
