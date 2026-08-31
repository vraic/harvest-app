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
end
