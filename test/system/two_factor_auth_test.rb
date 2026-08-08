require "application_system_test_case"

class TwoFactorAuthTest < ApplicationSystemTestCase
  setup do
    Capybara.reset_sessions!
    @password = "Password123!@#Strong"
    @user = User.create!(
      name: "2FA Test User",
      email_address: "two-factor-#{Process.pid}-#{SecureRandom.hex(6)}@example.com",
      password: @password,
      password_confirmation: @password,
      security_choice_made: true,
      onboarded: true
    )
  end

  test "2FA setup: enabling authenticator app" do
    login_as(@user)
    visit settings_path

    click_on "Setup Authenticator App"
    assert_text "Setup Two-Factor Authentication"

    # Extract secret from the page
    secret = find("code#otp-secret").text.strip
    totp = ROTP::TOTP.new(secret)

    # Use deterministic time for code generation and verification.
    # This is a best practice to avoid flakiness in CI caused by TOTP window expiry.
    travel_to Time.current do
      fill_in "otp_code", with: totp.now
      click_on "Verify and Enable 2FA"
    end

    assert_text "2FA has been enabled via OTP"
    assert @user.reload.otp_enabled?

    # Cleanup: disable 2FA
    visit settings_path
    click_on "Disable 2FA"
    assert_text "2FA has been disabled"
    refute @user.reload.otp_enabled?
  end

  test "2FA login phase 1: entering credentials redirects to 2FA prompt" do
    @user.update!(otp_required_for_login: true)

    sign_in_with_password(@user, @password)

    assert_current_path new_two_factor_verification_path, wait: 10
    assert_text "Two-Factor Verification"
  end

  test "2FA login phase 2: TOTP form accepts a 6-digit code" do
    @user.generate_otp_secret!
    @user.update!(otp_required_for_login: true)

    sign_in_with_password(@user, @password)

    assert_text "Two-Factor Verification"
    assert_text "Please enter the code from your authenticator app"

    totp = ROTP::TOTP.new(@user.reload.otp_secret.strip)
    travel_to Time.current do
      verify_code_with_retry { totp.now }
    end

    assert_selector "nav", visible: :any, wait: 10
  end

  test "2FA login phase 2: email OTP form accepts alphanumeric code" do
    @user.update!(otp_required_for_login: true, otp_secret: nil)

    sign_in_with_password(@user, @password)

    assert_text "Two-Factor Verification"
    assert_text "We've sent a verification code to your email address"

    token = "123ABC"
    @user.update!(email_otp_token: token, email_otp_sent_at: Time.current)
    verify_code_with_retry { token }

    assert_selector "nav", visible: :any, wait: 10
  end

  private

  def sign_in_with_password(user, password)
    visit new_session_path
    fill_in "Email", with: user.email_address
    click_button "Sign in with password"

    unless page.has_field?("Password (optional)", wait: 3)
      execute_script("document.querySelectorAll('[data-password-login-target=\"passwordFields\"]').forEach(el => el.classList.remove('hidden'))")
    end

    fill_in "Password (optional)", with: password
    click_button "Continue"
  end

  def verify_code_with_retry(max_attempts: 3)
    max_attempts.times do |attempt|
      code = yield
      assert code.present?, "Verification code should be present"

      begin
        fill_in "Verification Code", with: code.to_s
        find_button("Verify", wait: 10).click
      rescue Selenium::WebDriver::Error::StaleElementReferenceError, Selenium::WebDriver::Error::UnknownError
        raise if attempt == max_attempts - 1

        sleep 0.1
        next
      end

      return if has_no_current_path?(new_two_factor_verification_path, wait: 10)
      next if attempt < max_attempts - 1 && page.has_text?("Invalid verification code.", wait: 2)
    end

    assert_no_current_path new_two_factor_verification_path, wait: 10
  end
end
