require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrator = users(:administrator)
    @user = users(:one)

    sign_in_as(@administrator)
  end

  test "should get index" do
    get users_url
    assert_response :success
    assert_select "a", "Test Administrator"
  end

  test "show should have really delete for admin" do
    get user_url(@user)
    assert_response :success
    assert_select "button", "Really Delete"
  end

  test "show should not show really delete for non-admin" do
    sign_in_as(@user)
    get user_url(users(:two))
    assert_response :success
    assert_select "button", text: "Really Delete", count: 0
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: { user: { email_address: "new-user@example.com", password: SecureRandom.hex(12), name: @user.name } }
    end

    assert_redirected_to user_url(User.last)
  end

  test "signup requires a valid invite code" do
    sign_out

    with_signup_invite_code("my-secret-code") do
      assert_no_difference("User.count") do
        post users_url, params: {
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

  test "signup with valid invite code creates user" do
    sign_out

    with_signup_invite_code("my-secret-code") do
      assert_difference("User.count") do
        post users_url, params: {
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
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch user_url(@user), params: { user: { email_address: @user.email_address, password: SecureRandom.hex(10), name: @user.name } }
    assert_redirected_to user_url(@user)
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete user_url(@user)
    end

    assert_redirected_to users_url
    assert_not_nil User.with_deleted.find_by(id: @user.id).deleted_at
  end

  test "should really destroy user" do
    assert_difference("User.count", -1) do
      delete really_destroy_user_url(@user)
    end

    assert_redirected_to users_url
    assert_nil User.with_deleted.find_by(id: @user.id)
  end

  test "non-admin cannot really destroy user" do
    sign_in_as(@user)
    delete really_destroy_user_url(users(:two))
    assert_redirected_to users_url
    assert_equal "Only global admins can permanently delete users.", flash[:alert]
    assert_not_nil User.find(users(:two).id)
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
