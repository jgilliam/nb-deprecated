require 'test_helper'

class VotesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:votes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_vote
    assert_difference('Vote.count') do
      post :create, :vote => { }
    end

    assert_redirected_to vote_path(assigns(:vote))
  end

  def test_should_show_vote
    get :show, :id => votes(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => votes(:one).id
    assert_response :success
  end

  def test_should_update_vote
    put :update, :id => votes(:one).id, :vote => { }
    assert_redirected_to vote_path(assigns(:vote))
  end

  def test_should_destroy_vote
    assert_difference('Vote.count', -1) do
      delete :destroy, :id => votes(:one).id
    end

    assert_redirected_to votes_path
  end
end
