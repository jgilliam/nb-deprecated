require 'test_helper'

class EndorsementsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:endorsements)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_endorsement
    assert_difference('Endorsement.count') do
      post :create, :endorsement => { }
    end

    assert_redirected_to endorsement_path(assigns(:endorsement))
  end

  def test_should_show_endorsement
    get :show, :id => endorsements(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => endorsements(:one).id
    assert_response :success
  end

  def test_should_update_endorsement
    put :update, :id => endorsements(:one).id, :endorsement => { }
    assert_redirected_to endorsement_path(assigns(:endorsement))
  end

  def test_should_destroy_endorsement
    assert_difference('Endorsement.count', -1) do
      delete :destroy, :id => endorsements(:one).id
    end

    assert_redirected_to endorsements_path
  end
end
