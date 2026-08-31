require "application_system_test_case"

class SignupFlowTest < ApplicationSystemTestCase
  test "new user can signup, create a store, and see supplier widget" do
    original_invite_code = ENV["SIGNUP_INVITE_CODE"]
    ENV["SIGNUP_INVITE_CODE"] = "system-test-invite"

    # 1. Signup
    visit new_signup_url
    fill_in "Name", with: "New Store Owner"
    fill_in "Email", with: "owner@example.com"
    fill_in "Password", with: "ComplexPassword123!"
    fill_in "Invite code", with: "system-test-invite"
    click_button "Sign up"

    assert_text "How would you like to sign in?"
    click_on "Continue with email codes"

    assert_text "Tell us about yourself"
    click_on "I'm a Store Owner"

    # 2. Create a Store
    assert_current_path new_account_path
    fill_in "Name", with: "My Shiny Store"
    fill_in "Address", with: "123 Farm Lane"
    click_button "Create Account"

    assert_text "Account was successfully created"

    # 3. Check for Supplier tab in edit account page
    visit edit_account_path(Account.last)
    assert_text "General"
    assert_text "Stores We Supply"
  ensure
    ENV["SIGNUP_INVITE_CODE"] = original_invite_code
  end
end
