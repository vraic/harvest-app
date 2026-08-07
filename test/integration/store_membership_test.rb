require "test_helper"

class StoreMembershipTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "New Customer", email_address: "new@example.com", password: "ComplexPassword123!")
    @account = accounts(:one)
    sign_in_as(@user)
  end

  test "user can join a store from the dashboard" do
    get dashboard_path
    assert_select "h2", "Stores"
    assert_select "h3", @account.name

    assert_difference "Customer.count", 1 do
      assert_difference "AccountUser.count", 1 do
        post store_memberships_path, params: { account_id: @account.id }
      end
    end

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_equal @account.id, session[:managed_account_id]
    assert_match /You have successfully joined #{@account.name}/, response.body

    # Verify they are now a member and shown as customer
    get dashboard_path
    assert_equal "customer", @user.account_users.find_by(account: @account).user_role
  end

  test "user cannot join a store they are already a member of" do
    # Join first
    Customer.create!(account: @account, user: @user, name: @user.name, email_address: @user.email_address)

    get dashboard_path
    assert_equal "customer", @user.account_users.find_by(account: @account).user_role

    # Try to post anyway
    post store_memberships_path, params: { account_id: @account.id }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match /You are already a member of #{@account.name}/, response.body
  end
end
