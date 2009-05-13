require 'test_helper'

class LettersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:letters)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_letter
    assert_difference('Letter.count') do
      post :create, :letter => { }
    end

    assert_redirected_to letter_path(assigns(:letter))
  end

  def test_should_show_letter
    get :show, :id => letters(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => letters(:one).id
    assert_response :success
  end

  def test_should_update_letter
    put :update, :id => letters(:one).id, :letter => { }
    assert_redirected_to letter_path(assigns(:letter))
  end

  def test_should_destroy_letter
    assert_difference('Letter.count', -1) do
      delete :destroy, :id => letters(:one).id
    end

    assert_redirected_to letters_path
  end
end
