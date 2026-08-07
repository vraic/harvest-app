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
  end

  test "admin sees account switcher with authorized support requests" do
    admin = users(:administrator)
    login_as(admin)

    # Ensure no memberships for this test
    ActsAsTenant.without_tenant do
      admin.account_users.delete_all
      SupportRequest.delete_all
    end

    visit dashboard_path
    assert_no_text "Switch Account"

    # Create authorized support request
    ActsAsTenant.without_tenant do
      SupportRequest.create!(account: accounts(:one), requester: users(:one), message: "Help", status: :accepted, expires_at: 1.day.from_now)
    end

    visit dashboard_path
    assert_text "Switch Account"
  end
end
