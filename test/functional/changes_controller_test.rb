require 'test_helper'

class ChangesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:changes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_change
    assert_difference('Change.count') do
      post :create, :change => { }
    end

    assert_redirected_to change_path(assigns(:change))
  end

  def test_should_show_change
    get :show, :id => changes(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => changes(:one).id
    assert_response :success
  end

  def test_should_update_change
    put :update, :id => changes(:one).id, :change => { }
    assert_redirected_to change_path(assigns(:change))
  end

  def test_should_destroy_change
    assert_difference('Change.count', -1) do
      delete :destroy, :id => changes(:one).id
    end

    assert_redirected_to changes_path
  end
end
