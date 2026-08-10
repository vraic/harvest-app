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

    if @user.admin?
      assert_redirected_to madmin_root_path
    elsif @user.account_users.active.where(user_role: [ :store_manager, :store_staff ]).exists?
      assert_redirected_to dashboard_path
    else
      assert_redirected_to shop_path
    end
    assert_not_nil cookies[:session_id]
  end

  test "create with valid credentials and no memberships redirects to shop" do
    user = users(:unassigned)
    user.update!(otp_required_for_login: false, prefers_email_login: false)

    post session_path, params: { email_address: user.email_address, password: "password" }

    assert_redirected_to shop_path
    assert_not_nil cookies[:session_id]
  end

  test "create with valid credentials and staff membership redirects to dashboard" do
    user = users(:two)
    user.update!(otp_required_for_login: false, prefers_email_login: false)

    post session_path, params: { email_address: user.email_address, password: "password" }

    assert_redirected_to dashboard_path
    assert_not_nil cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create with valid credentials and forced reset redirects to password reset" do
    @user.update!(otp_required_for_login: false, prefers_email_login: false, force_password_reset: true)
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_response :redirect
    assert_match(%r{\A/passwords/.+/edit\z}, URI.parse(response.location).path)
    assert_nil session[:otp_user_id]
    assert_nil session[:security_setup_user_id]
    assert_nil cookies[:session_id]
    assert_equal "Please reset your password to continue.", flash[:alert]
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

  test "create without password for unknown email redirects to signup" do
    assert_no_difference("User.count") do
      assert_no_enqueued_emails do
        post session_path, params: { email_address: "signup-only@example.com" }
      end
    end

    assert_redirected_to new_user_path(email_address: "signup-only@example.com")
    assert_equal "No account found for that email. Please sign up first.", flash[:alert]
    assert_nil session[:otp_user_id]
    assert_nil session[:security_setup_user_id]
  end

  test "create without email redirects back to signin" do
    post session_path, params: { email_address: "   " }

    assert_redirected_to new_session_path
    assert_equal "Enter your email address.", flash[:alert]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
