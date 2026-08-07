require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials and 2FA required redirects to 2FA" do
    @user.update!(otp_required_for_login: true)
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to new_two_factor_verification_path
    assert_equal @user.id, session[:otp_user_id]
    assert_nil cookies[:session_id]
  end

  test "create with valid credentials and 2FA not required signs in directly" do
    @user.update!(otp_required_for_login: false, prefers_email_login: false)
    post session_path, params: { email_address: @user.email_address, password: "password" }

    # Users are now redirected to dashboard or shop based on role
    if @user.admin?
      assert_redirected_to dashboard_path
    elsif @user.account_users.any? && @user.account_users.all?(&:customer?)
      assert_redirected_to shop_path
    else
      assert_redirected_to dashboard_path
    end
    assert_not_nil cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create without password sends one-time code for existing user" do
    assert_enqueued_emails 1 do
      post session_path, params: { email_address: @user.email_address }
    end

    assert_redirected_to new_two_factor_verification_path
    assert_equal @user.id, session[:otp_user_id]
    assert_equal @user.id, session[:security_setup_user_id]
    assert User.find(@user.id).email_otp_token.present?
  end

  test "create without password signs up new user and sends code" do
    assert_difference("User.count", 1) do
      assert_enqueued_emails 1 do
        post session_path, params: { email_address: "signup-only@example.com" }
      end
    end

    user = User.find_by(email_address: "signup-only@example.com")
    assert_not_nil user
    assert user.prefers_email_login?
    assert_redirected_to new_two_factor_verification_path
    assert_equal user.id, session[:otp_user_id]
    assert_equal user.id, session[:security_setup_user_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
