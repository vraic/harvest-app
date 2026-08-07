require "application_system_test_case"

class AccountSwitcherTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @account_one = accounts(:one)
    @account_two = accounts(:two)

    # Give user :one access to account :two as well
    # We use unscoped because fixtures might have different tenants active
    ActsAsTenant.without_tenant do
      AccountUser.create!(account: @account_two, user: @user, user_role: :store_staff)
    end
  end

  test "can switch between accounts on desktop" do
    login_as @user
    visit dashboard_path

    # Since user has multiple accounts, Current.account is nil initially
    # Open switcher
    click_button "Switch Account", match: :first
    assert_selector "#account-switcher", visible: true, wait: 10

    within "#account-switcher" do
      assert_text "Switch Account"
      assert_text @account_one.name
      assert_text @account_two.name
      assert_text "Store Manager" # for account one
      assert_text "Store Staff"   # for account two

      # Initially none is active because Current.account is nil
      within("li", text: @account_one.name) do
        click_button "Switch"
      end
    end

    assert_text "Switched to #{@account_one.name}"
    # Verify new role display
    assert_text "#{@account_one.name} (Store Manager)"
  end

  test "list remains complete after switching to an account" do
    login_as @user
    visit dashboard_path

    # Switch to account one
    click_button "Switch Account", match: :first
    assert_selector "#account-switcher", visible: true, wait: 10
    within "#account-switcher" do
      within("li", text: @account_one.name) do
        click_button "Switch"
      end
    end

    assert_text "Switched to #{@account_one.name}"

    # Open switcher again
    click_button "Switch Account", match: :first
    assert_selector "#account-switcher", visible: true, wait: 10

    within "#account-switcher" do
      assert_text @account_one.name
      assert_text @account_two.name
    end
  end

  test "can switch between accounts on mobile" do
    resize_to_mobile
    login_as @user
    visit dashboard_path

    click_button "Open sidebar"

    # Open switcher
    click_button "Switch Account"
    assert_selector "#account-switcher", visible: true, wait: 10

    within "#account-switcher" do
      within("li", text: @account_one.name) do
        click_button "Switch"
      end
    end

    assert_text "Switched to #{@account_one.name}"

    click_button "Open sidebar"
    assert_text "#{@account_one.name} (Store Manager)"
  end

  test "shows B2B accounts in switcher" do
    @account_four = accounts(:four)
    # Create a B2B customer relationship
    # User one is staff of account one.
    # We want user one to be a customer of account four via account one.
    ActsAsTenant.without_tenant do
      Customer.create!(account: @account_four, customer_account: @account_one, name: "B2B Customer", email_address: @user.email_address)
    end

    login_as @user
    visit dashboard_path

    click_button "Switch Account", match: :first
    assert_selector "#account-switcher", visible: true, wait: 10

    within "#account-switcher" do
      assert_text @account_four.name
      assert_text "Customer"

      within("li", text: @account_four.name) do
        click_button "Switch"
      end
    end

    assert_text "Switched to #{@account_four.name}"
    # ManagedAccountsController will create an AccountUser with role 'customer' when switching
    assert_text "#{@account_four.name} (Customer)"
  end

  test "switch account button only shows if user has more than one account" do
    @single_account_user = User.create!(
      name: "Single User",
      email_address: "single-#{Time.now.to_i}@example.com",
      password: "Password123!@#Strong",
      password_confirmation: "Password123!@#Strong",
      onboarded: true
    )
    @new_account = Account.create!(name: "Single Store", owner: @single_account_user)

    login_as @single_account_user
    visit dashboard_path

    assert_no_button "Switch Account"
  end
end
