require 'test_helper'

class PrioritiesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:priorities)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_priority
    assert_difference('Priority.count') do
      post :create, :priority => { }
    end

    assert_redirected_to priority_path(assigns(:priority))
  end

  def test_should_show_priority
    get :show, :id => priorities(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => priorities(:one).id
    assert_response :success
  end

  def test_should_update_priority
    put :update, :id => priorities(:one).id, :priority => { }
    assert_redirected_to priority_path(assigns(:priority))
  end

  def test_should_destroy_priority
    assert_difference('Priority.count', -1) do
      delete :destroy, :id => priorities(:one).id
    end

    assert_redirected_to priorities_path
  end
end
