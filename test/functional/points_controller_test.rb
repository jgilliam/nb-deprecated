require 'test_helper'

class PointsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:points)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_point
    assert_difference('Point.count') do
      post :create, :point => { }
    end

    assert_redirected_to point_path(assigns(:point))
  end

  def test_should_show_point
    get :show, :id => points(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => points(:one).id
    assert_response :success
  end

  def test_should_update_point
    put :update, :id => points(:one).id, :point => { }
    assert_redirected_to point_path(assigns(:point))
  end

  def test_should_destroy_point
    assert_difference('Point.count', -1) do
      delete :destroy, :id => points(:one).id
    end

    assert_redirected_to points_path
  end
end
