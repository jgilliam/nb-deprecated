require 'test_helper'

class SignupsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:signups)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_signup
    assert_difference('Signup.count') do
      post :create, :signup => { }
    end

    assert_redirected_to signup_path(assigns(:signup))
  end

  def test_should_show_signup
    get :show, :id => signups(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => signups(:one).id
    assert_response :success
  end

  def test_should_update_signup
    put :update, :id => signups(:one).id, :signup => { }
    assert_redirected_to signup_path(assigns(:signup))
  end

  def test_should_destroy_signup
    assert_difference('Signup.count', -1) do
      delete :destroy, :id => signups(:one).id
    end

    assert_redirected_to signups_path
  end
end
