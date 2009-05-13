require 'test_helper'

class WebpagesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:webpages)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_webpage
    assert_difference('Webpage.count') do
      post :create, :webpage => { }
    end

    assert_redirected_to webpage_path(assigns(:webpage))
  end

  def test_should_show_webpage
    get :show, :id => webpages(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => webpages(:one).id
    assert_response :success
  end

  def test_should_update_webpage
    put :update, :id => webpages(:one).id, :webpage => { }
    assert_redirected_to webpage_path(assigns(:webpage))
  end

  def test_should_destroy_webpage
    assert_difference('Webpage.count', -1) do
      delete :destroy, :id => webpages(:one).id
    end

    assert_redirected_to webpages_path
  end
end
