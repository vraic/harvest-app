require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_signup_url
    assert_response :success
  end

  test "new prefills email address from params" do
    get new_signup_url(email_address: "prefill@example.com")
    assert_response :success
    assert_select "input[name='user[email_address]'][value='prefill@example.com']"
  end

  test "new links to terms and privacy pages" do
    get new_signup_url

    assert_response :success
    assert_select "a[href=?]", terms_path, text: "Terms of Service"
    assert_select "a[href=?]", privacy_path, text: "Privacy Policy"
  end

  test "signup requires a valid invite code" do
    with_signup_invite_code("my-secret-code") do
      assert_no_difference("User.count") do
        post signup_url, params: {
          user: {
            email_address: "signup-without-code@example.com",
            password: "StrongPassword123!",
            name: "Signup User"
          }
        }
      end
    end

    assert_response :unprocessable_content
    assert_select "div", /valid invite code/i
  end

  test "signup with valid invite code creates user and signs them in" do
    with_signup_invite_code("my-secret-code") do
      assert_difference("User.count") do
        post signup_url, params: {
          user: {
            email_address: "signup-with-code@example.com",
            password: "StrongPassword123!",
            name: "Invite Signup"
          },
          signup_invite_code: "my-secret-code"
        }
      end
    end

    assert_redirected_to security_setup_path
    assert_not_nil cookies[:session_id]
  end

  test "signup with account_id creates customer and joins account" do
    account = accounts(:one)

    with_signup_invite_code("my-secret-code") do
      assert_difference("Customer.count") do
        post signup_url, params: {
          user: {
            email_address: "signup-for-account@example.com",
            password: "StrongPassword123!",
            name: "Account Signup"
          },
          signup_invite_code: "my-secret-code",
          account_id: account.id
        }
      end
    end

    user = User.find_by(email_address: "signup-for-account@example.com")
    assert_equal account.id, user.customers.first.account_id
  end

  private
    def with_signup_invite_code(code)
      original_code = ENV["SIGNUP_INVITE_CODE"]
      ENV["SIGNUP_INVITE_CODE"] = code

      yield
    ensure
      ENV["SIGNUP_INVITE_CODE"] = original_code
    end
end
