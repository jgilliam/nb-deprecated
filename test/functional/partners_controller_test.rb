require 'test_helper'

class PartnersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:partners)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_partner
    assert_difference('Partner.count') do
      post :create, :partner => { }
    end

    assert_redirected_to partner_path(assigns(:partner))
  end

  def test_should_show_partner
    get :show, :id => partners(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => partners(:one).id
    assert_response :success
  end

  def test_should_update_partner
    put :update, :id => partners(:one).id, :partner => { }
    assert_redirected_to partner_path(assigns(:partner))
  end

  def test_should_destroy_partner
    assert_difference('Partner.count', -1) do
      delete :destroy, :id => partners(:one).id
    end

    assert_redirected_to partners_path
  end
end
