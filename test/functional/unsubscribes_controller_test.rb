require 'test_helper'

class UnsubscribesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:unsubscribes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_unsubscribe
    assert_difference('Unsubscribe.count') do
      post :create, :unsubscribe => { }
    end

    assert_redirected_to unsubscribe_path(assigns(:unsubscribe))
  end

  def test_should_show_unsubscribe
    get :show, :id => unsubscribes(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => unsubscribes(:one).id
    assert_response :success
  end

  def test_should_update_unsubscribe
    put :update, :id => unsubscribes(:one).id, :unsubscribe => { }
    assert_redirected_to unsubscribe_path(assigns(:unsubscribe))
  end

  def test_should_destroy_unsubscribe
    assert_difference('Unsubscribe.count', -1) do
      delete :destroy, :id => unsubscribes(:one).id
    end

    assert_redirected_to unsubscribes_path
  end
end
