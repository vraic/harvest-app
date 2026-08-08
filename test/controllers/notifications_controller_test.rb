require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @staff_user = users(:one)
    @staff_membership = account_users(:one)
    sign_in_as(@staff_user)
  end

  test "staff can view account-scoped notifications" do
    account = @staff_membership.account
    foreign_account = accounts(:two)

    local_event = TaskAssignedNotifier.with(record: tasks(:one), account_id: account.id).deliver(@staff_user)
    foreign_event = TaskAssignedNotifier.with(record: tasks(:two), account_id: foreign_account.id).deliver(@staff_user)

    patch managed_account_url, params: { account_id: account.id, return_to: notifications_path }
    follow_redirect!

    assert_response :success
    assert_includes response.body, local_event.notifications.first.event.message
    assert_not_includes response.body, foreign_event.notifications.first.event.message
  end

  test "non-staff users are redirected" do
    sign_out
    sign_in_as(users(:three))

    get notifications_url

    assert_redirected_to shop_path
    follow_redirect!
    assert_match "Access denied.", response.body
  end
end
