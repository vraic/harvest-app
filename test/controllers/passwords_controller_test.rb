require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "Reset email sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "Reset email sent"
  end

  test "create shows an error when reset instructions cannot be sent" do
    failing_delivery = Class.new do
      def deliver_later
        raise StandardError, "queue unavailable"
      end

      def deliver_now
        raise StandardError, "smtp unavailable"
      end
    end.new

    with_stubbed_password_mailer_reset(failing_delivery) do
      post passwords_path, params: { email_address: @user.email_address }
    end

    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "Try again"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "Reset link expired"
  end

  test "update" do
    @user.update!(force_password_reset: true)

    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "ComplexPassword123!", password_confirmation: "ComplexPassword123!" }
      assert_redirected_to new_session_path
    end

    assert_not @user.reload.force_password_reset?

    follow_redirect!
    assert_notice "Password reset"
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "no", password_confirmation: "match" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_notice "Passwords didn't match"
  end

  private
    def with_stubbed_password_mailer_reset(delivery)
      singleton = PasswordsMailer.singleton_class

      singleton.send(:define_method, :reset) { |_user| delivery }

      yield
    ensure
      singleton.send(:remove_method, :reset)
    end

    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
