require "application_system_test_case"

class SecuritySetupSidebarTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Security User", email_address: "security@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong", prefers_email_login: true)
  end

  test "sidebar is hidden on security setup page" do
    # Log in in a way that triggers security setup
    # Or just visit it directly if it allows (it usually needs a session variable)

    # We'll use the UI flow
    visit new_session_path
    fill_in "Email", with: @user.email_address
    click_button "Continue" # Magic link login

    # Get OTP
    token = nil
    50.times do
      token = User.uncached { User.find(@user.id).email_otp_token }
      break if token.present?
      sleep 0.1
    end

    fill_in "Verification Code", with: token
    click_button "Verify"

    assert_current_path security_setup_path

    # Check that sidebar is NOT visible
    assert_no_selector "#desktop-sidebar-main-nav", visible: true
    assert_no_selector "dialog#sidebar", visible: true

    # Continue to onboarding
    click_on "Continue with email codes"
    assert_current_path onboarding_path
    assert_no_selector "#desktop-sidebar-main-nav", visible: true

    # Go to New Account page
    click_on "I'm a Store Owner"
    assert_current_path new_account_path
    assert_no_selector "#desktop-sidebar-main-nav", visible: true
  end
end
