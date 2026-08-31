require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  test "visiting new sessions page" do
    visit new_session_url

    assert_selector "h1", text: "Sign in to Harvest"
  end

  test "signing in with a password account shows the password step" do
    user = users(:one)
    user.update!(prefers_email_login: false, otp_required_for_login: false)

    visit new_session_url
    fill_in "Email", with: user.email_address
    click_button "Continue"

    assert_selector "label", text: "Password"
    fill_in "Password", with: "password"
    click_button "Sign in"

    assert_no_selector "h1", text: "Sign in to Harvest"
  end

  test "signing in with a magic link account emails a one-time code" do
    user = users(:one)
    user.update!(prefers_email_login: true)

    visit new_session_url
    fill_in "Email", with: user.email_address
    click_button "Continue"

    assert_selector "h1", text: "Two-Factor Verification"
  end

  test "sign up link navigates to the signup page" do
    visit new_session_url
    click_link "Sign up"

    assert_selector "h1", text: "Create your account"
  end
end
