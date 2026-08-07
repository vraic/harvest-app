require "test_helper"

class TwoFactorVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(security_choice_made: true, onboarded: true, prefers_email_login: false)
  end

  test "new regenerates email otp when existing token is expired" do
    @user.update!(otp_required_for_login: true)
    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to new_two_factor_verification_path

    stale_token = User.find(@user.id).email_otp_token
    @user.update_columns(email_otp_sent_at: 16.minutes.ago)

    get new_two_factor_verification_path
    assert_response :success

    refreshed_token = User.find(@user.id).email_otp_token
    assert_not_equal stale_token, refreshed_token
  end

  test "create with valid TOTP signs the user in" do
    @user.generate_otp_secret!
    @user.update!(otp_required_for_login: true)

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to new_two_factor_verification_path
    assert_equal @user.id, session[:otp_user_id]

    travel_to Time.current do
      code = ROTP::TOTP.new(@user.reload.otp_secret.strip).now
      post two_factor_verification_path, params: { otp_code: code }
    end

    assert_response :redirect
    refute_equal new_two_factor_verification_path, URI.parse(response.location).path
    assert_equal "Signed in successfully.", flash[:notice]
    assert_nil session[:otp_user_id]
    assert_not_nil cookies[:session_id]
  end

  test "create with valid email OTP signs the user in" do
    @user.update!(otp_required_for_login: true, otp_secret: nil)

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to new_two_factor_verification_path
    assert_equal @user.id, session[:otp_user_id]

    token = User.find(@user.id).email_otp_token
    assert token.present?

    post two_factor_verification_path, params: { otp_code: token }

    assert_response :redirect
    refute_equal new_two_factor_verification_path, URI.parse(response.location).path
    assert_equal "Signed in successfully.", flash[:notice]
    assert_nil session[:otp_user_id]
    assert_not_nil cookies[:session_id]
    assert_nil User.find(@user.id).email_otp_token
  end
end
