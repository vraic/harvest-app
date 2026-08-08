require "application_system_test_case"

class AccountStaffManagementTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Store Owner", email_address: "owner-staff@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong", onboarded: true, security_choice_made: true)
    @staff_email = "staff-management@example.com"
  end

  test "creating a store automatically assigns store_manager role" do
    login_as(@user)
    visit settings_path

    click_on "Convert account to a store account"
    fill_in "Name", with: "My New Store"
    click_on "Create Account"

    assert_text "Account was successfully created."

    # Check if user is manager in staff tab
    visit edit_account_path(Account.last, tab: "staff")
    within "tr##{dom_id(AccountUser.last)}" do
      assert_text "Store Owner"
      assert_text "Store Manager"
    end

    assert_text "Staff"
  end

  test "adding, editing and archiving staff" do
    @account = Account.create!(name: "Test Store", owner: @user)

    login_as(@user)
    visit edit_account_path(@account, tab: "staff")

    # Add new staff
    click_on "Invite User"
    fill_in "Email address", with: @staff_email
    select "Store Staff", from: "User role"
    click_on "Create Account user"

    assert_text "Account user was successfully invited."
    assert_text @staff_email
    assert_text "Store Staff"

    # Edit staff role
    staff_user = User.find_by(email_address: @staff_email)
    staff_account_user = AccountUser.find_by(user: staff_user, account: @account)

    within "tr##{dom_id(staff_account_user)}" do
      click_on "Edit"
    end

    select "Store Manager", from: "User role"
    click_on "Update Account user"

    assert_text "Account user was successfully updated."
    within "tr##{dom_id(staff_account_user)}" do
      assert_text "Store Manager"
    end

    # Archive staff
    within "tr##{dom_id(staff_account_user)}" do
      accept_confirm do
        click_on "Archive"
      end
    end

    assert_text "Account user was successfully archived."
    assert_text "Archived Staff"
  end

  test "adding existing user as staff" do
    existing_user = User.create!(name: "Existing User", email_address: "existing@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")
    @account = Account.create!(name: "Test Store", owner: @user)

    login_as(@user)
    visit edit_account_path(@account, tab: "staff")

    click_on "Invite User"
    fill_in "Email address", with: "existing@example.com"
    select "Store Staff", from: "User role"
    click_on "Create Account user"

    assert_text "Account user was successfully invited."
    assert_text "Existing User"
    assert_text "Store Staff"
  end
end
