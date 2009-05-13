require 'test_helper'

class RevisionsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:revisions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_revision
    assert_difference('Revision.count') do
      post :create, :revision => { }
    end

    assert_redirected_to revision_path(assigns(:revision))
  end

  def test_should_show_revision
    get :show, :id => revisions(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => revisions(:one).id
    assert_response :success
  end

  def test_should_update_revision
    put :update, :id => revisions(:one).id, :revision => { }
    assert_redirected_to revision_path(assigns(:revision))
  end

  def test_should_destroy_revision
    assert_difference('Revision.count', -1) do
      delete :destroy, :id => revisions(:one).id
    end

    assert_redirected_to revisions_path
  end
end
