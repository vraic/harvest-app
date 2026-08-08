require "application_system_test_case"

class CustomerInterfaceTest < ApplicationSystemTestCase
  setup do
    @user = users(:one) # A customer user
    login_as(@user)
  end

  test "customer with only customer roles does not see account switcher" do
    # User one in fixtures might have multiple roles, let's ensure they are only customers
    ActsAsTenant.without_tenant do
      @user.account_users.update_all(user_role: :customer)
    end

    visit dashboard_path
    assert_no_text "Switch Account"
    assert_no_selector "button", text: "Switch Account"
  end

  test "staff user sees account switcher" do
    ActsAsTenant.without_tenant do
      @user.account_users.first.update!(user_role: :store_staff)
      AccountUser.unscoped.find_or_create_by!(user: @user, account: accounts(:two)) do |account_user|
        account_user.user_role = :store_staff
      end
    end

    visit dashboard_path
    assert_text "Switch Account"
  end

  test "can manage newsletter subscriptions across stores" do
    @user = users(:three)
    login_as(@user)

    # Create another membership and a newsletter for it
    ActsAsTenant.without_tenant do
      c1 = Customer.find_by(user: @user, account: accounts(:one))
      c1.update!(subscribed_to_newsletter: true, subscribed_at: 1.day.ago)

      Customer.create!(user: @user, account: accounts(:two), name: @user.name, email_address: @user.email_address, subscribed_to_newsletter: true, subscribed_at: 1.day.ago)
      Newsletter.create!(account: accounts(:two), subject: "Account Two News", content: "Hello", sent_at: Time.current)
      Newsletter.create!(account: accounts(:one), subject: "Account One News", content: "Hi", sent_at: Time.current)
    end

    visit customer_newsletters_path

    assert_text "Your Newsletters"
    assert_text accounts(:one).name
    assert_text accounts(:two).name

    # Check archives
    assert_text "Account One News"
    assert_text "Account Two News"

    # Unsubscribe from one
    within "[data-testid='subscription-card-#{accounts(:two).id}']" do
      click_on "Unsubscribe"
    end

    assert_text "You have unsubscribed from #{accounts(:two).name}"
  end

  test "shop filtering based on classification" do
    supplier_authorization = nil

    ActsAsTenant.without_tenant do
      accounts(:one).update!(is_b2c: true, is_b2b: false, is_internal: false)
      accounts(:two).update!(is_b2c: false, is_b2b: true, is_internal: false)
      # Create an internal account
      Account.create!(name: "Internal Store", owner: users(:one), is_b2c: false, is_b2b: false, is_internal: true)
    end

    # As a customer only
    ActsAsTenant.without_tenant do
      @user.account_users.update_all(user_role: :customer)
    end
    visit shop_path
    assert_text accounts(:one).name
    assert_no_text accounts(:two).name
    assert_no_text "Internal Store"

    # As a staff member
    ActsAsTenant.without_tenant do
      @user.account_users.first.update!(user_role: :store_staff)
      supplier_authorization = Supplier.create!(
        account: accounts(:two),
        supplier_account: accounts(:one),
        name: accounts(:one).name,
        email_address: "classified-supplier@example.com"
      )
    end
    visit shop_path
    assert_text accounts(:one).name
    assert_text accounts(:two).name
    assert_no_text "Internal Store"

    # As an admin
    login_as(users(:administrator))
    visit shop_path
    assert_text accounts(:one).name
    assert_text accounts(:two).name
    assert_text "Internal Store"
  ensure
    supplier_authorization&.destroy!
  end

  test "admin sees account switcher only with multiple authorized support requests" do
    admin = users(:administrator)
    login_as(admin)

    # Ensure no memberships for this test
    ActsAsTenant.without_tenant do
      admin.account_users.delete_all
      SupportRequest.delete_all
    end

    visit dashboard_path
    assert_no_text "Switch Account"

    # One authorized support request is not enough to show switching
    ActsAsTenant.without_tenant do
      SupportRequest.create!(account: accounts(:one), requester: users(:one), message: "Help", status: :accepted, expires_at: 1.day.from_now)
    end

    visit dashboard_path
    assert_no_text "Switch Account"

    ActsAsTenant.without_tenant do
      SupportRequest.create!(account: accounts(:two), requester: users(:two), message: "Need support", status: :accepted, expires_at: 1.day.from_now)
    end

    visit dashboard_path
    assert_text "Switch Account"
  end

  test "admin does not see account switcher without active support authorization even with account membership" do
    admin = users(:administrator)
    login_as(admin)

    ActsAsTenant.without_tenant do
      SupportRequest.delete_all
      AccountUser.unscoped.find_or_create_by!(user: admin, account: accounts(:one)) do |account_user|
        account_user.user_role = :store_manager
      end
    end

    visit dashboard_path

    assert_no_text "Switch Account"
  end

  test "admin acting on behalf uses staff navigation while keeping admin dashboard actions" do
    admin = users(:administrator)

    ActsAsTenant.without_tenant do
      SupportRequest.delete_all
      SupportRequest.create!(account: accounts(:one), requester: users(:one), message: "Support", status: :accepted, expires_at: 1.day.from_now)
    end

    login_as(admin)
    select_account(accounts(:one).name)
    visit dashboard_path

    within "#desktop-sidebar-main-nav" do
      assert_text "Tasks"
      assert_text "People"
      click_button "People"
      assert_text "Customer View"
      assert_no_text "Quick links"
      assert_no_text "Administration"
      assert_no_text "Support Requests"
    end

    within "#admin-dashboard-actions" do
      assert_text "Administration"
      assert_text "Support Requests"
      assert_no_text "Visit Shop"
      assert_no_text "Visit Shop & Order"
    end
  end
end
