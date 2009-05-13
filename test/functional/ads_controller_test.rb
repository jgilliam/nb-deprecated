require 'test_helper'

class AdsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:ads)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_ad
    assert_difference('Ad.count') do
      post :create, :ad => { }
    end

    assert_redirected_to ad_path(assigns(:ad))
  end

  def test_should_show_ad
    get :show, :id => ads(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => ads(:one).id
    assert_response :success
  end

  def test_should_update_ad
    put :update, :id => ads(:one).id, :ad => { }
    assert_redirected_to ad_path(assigns(:ad))
  end

  def test_should_destroy_ad
    assert_difference('Ad.count', -1) do
      delete :destroy, :id => ads(:one).id
    end

    assert_redirected_to ads_path
  end
end
