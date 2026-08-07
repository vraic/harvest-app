require "application_system_test_case"

class CustomerNewslettersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @customer = customers(:one) # Assumed to be customer of account one

    # Ensure @customer is linked to @user
    @customer.update!(user: @user)

    # Ensure role is customer
    ActsAsTenant.without_tenant do
      AccountUser.find_by(account: @account, user: @user)&.destroy
      AccountUser.create!(account: @account, user: @user, user_role: :customer)
    end
  end

  test "customer can see subscribe box when not subscribed" do
    @customer.update!(subscribed_to_newsletter: false, subscribed_at: nil)

    login_as @user
    visit dashboard_path

    # User should have Current.account set to @account because it's their only account
    # and we made them a customer in setup.

    assert_link "Newsletters"
    click_link "Newsletters"

    assert_text "Your Newsletters"
    assert_button "Subscribe"
  end

  test "customer can subscribe and see newsletters sent after subscription" do
    @customer.update!(subscribed_to_newsletter: false, subscribed_at: nil)

    # Create newsletters
    old_newsletter = nil
    new_newsletter = nil

    ActsAsTenant.with_tenant(@account) do
      old_newsletter = Newsletter.create!(subject: "Old News", content: "Content", sent_at: 1.day.ago)
      new_newsletter = Newsletter.create!(subject: "New News", content: "Content", sent_at: 1.hour.from_now)
    end

    login_as @user
    visit customer_newsletters_path

    click_button "Subscribe"

    assert_text "You have successfully subscribed to the newsletter."
    assert_text "New News"
    assert_no_text "Old News"

    click_link "View"
    assert_text "New News"
    assert_text "Content"
  end

  test "newsletter link is not visible to staff (they see management one)" do
    ActsAsTenant.without_tenant do
      AccountUser.find_by(account: @account, user: @user)&.update!(user_role: :store_manager)
    end

    login_as @user
    visit customer_newsletters_path

    # Should be redirected by set_customer if they don't have a Customer record
    # Wait, staff might have a customer record.
    # But sidebar link for customer_newsletters_path is wrapped in if customer?

    visit dashboard_path
    # On desktop, newsletters_path is visible for staff
    within "#desktop-sidebar-main-nav" do
       assert_link "Newsletters"
       # We should check the href to ensure it's the management one
       assert_selector "a[href='#{newsletters_path}']"
       assert_no_selector "a[href='#{customer_newsletters_path}']"
    end
  end

  test "subscription checkboxes are removed from settings page" do
    login_as @user
    visit settings_path

    assert_no_text "Subscribe to customer newsletter"
    assert_no_text "Subscribe to supplier newsletter"
    assert_no_selector "input[name='subscribed_to_newsletter_customer']"
    assert_no_selector "input[name='subscribed_to_newsletter_supplier']"
  end
end
