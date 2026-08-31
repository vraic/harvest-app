require "application_system_test_case"

class TasksFlowTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    grant_support_access(accounts(:one))
    login_as(@admin)
  end

  test "creating a task and seeing it on the index" do
    select_account("Account One")

    visit tasks_url
    assert_selector "h1", text: "Tasks"
    click_link "New Task"

    assert_selector "h1", text: "New task"
    fill_in "task_title", with: "Real-time task"
    fill_in "task_description", with: "This task should appear instantly"
    select users(:one).name, from: "Responsible"

    click_button "Create Task"

    assert_text "Task created"
    assert_text "Real-time task"
    assert_text users(:one).name
  end

  private
end
