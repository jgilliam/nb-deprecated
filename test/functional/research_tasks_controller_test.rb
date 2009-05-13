require 'test_helper'

class ResearchTasksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:research_tasks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create research_task" do
    assert_difference('ResearchTask.count') do
      post :create, :research_task => { }
    end

    assert_redirected_to research_task_path(assigns(:research_task))
  end

  test "should show research_task" do
    get :show, :id => research_tasks(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => research_tasks(:one).id
    assert_response :success
  end

  test "should update research_task" do
    put :update, :id => research_tasks(:one).id, :research_task => { }
    assert_redirected_to research_task_path(assigns(:research_task))
  end

  test "should destroy research_task" do
    assert_difference('ResearchTask.count', -1) do
      delete :destroy, :id => research_tasks(:one).id
    end

    assert_redirected_to research_tasks_path
  end
end
