require "test_helper"

class AccountUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrator = users(:administrator)
    @account_user = account_users(:one)
    @account = @account_user.account
    @archivable_user = User.create!(
      name: "Archivable Staff",
      email_address: "archivable-staff-#{SecureRandom.hex(6)}@example.com",
      password: "Password123!@#Strong",
      password_confirmation: "Password123!@#Strong"
    )
    @archivable_account_user = AccountUser.create!(account: @account, user: @archivable_user, user_role: :store_staff)
    @unassigned_user = users(:unassigned)

    sign_in_as(@administrator)
  end

  test "should get index" do
    get account_account_users_url(@account)
    assert_response :success
  end

  test "should get new" do
    get new_account_account_user_url(@account)
    assert_response :success
  end

  test "should create account_user" do
    assert_difference("AccountUser.count") do
      post account_account_users_url(@account), params: {
        email_address: "newuser@example.com",
        account_user: { user_role: "store_staff" }
      }
    end

    assert_redirected_to edit_account_url(@account, tab: "staff")
  end

  test "should show account_user" do
    get account_user_url(@account_user)
    assert_response :success
  end

  test "should get edit" do
    get edit_account_user_url(@account_user)
    assert_response :success
  end

  test "should update account_user" do
    patch account_user_url(@account_user), params: { account_user: { user_role: "store_staff" } }
    assert_redirected_to edit_account_url(@account, tab: "staff")
  end

  test "should archive account_user" do
    assert_no_difference("AccountUser.count") do
      delete account_user_url(@archivable_account_user)
    end

    assert_redirected_to edit_account_url(@account, tab: "staff")
    assert @archivable_account_user.reload.archived?
  end

  test "should not archive last store manager" do
    delete account_user_url(@account_user)

    assert_redirected_to edit_account_url(@account, tab: "staff")
    refute @account_user.reload.archived?
  end

  test "store manager cannot archive themselves" do
    sign_in_as(users(:one))

    delete account_user_url(@account_user)

    assert_redirected_to edit_account_url(@account, tab: "staff")
    refute @account_user.reload.archived?
  end

  test "should restore archived account_user on invite" do
    @account_user.update!(archived_at: 1.day.ago)

    assert_no_difference("AccountUser.count") do
      post account_account_users_url(@account), params: {
        email_address: @account_user.user.email_address,
        account_user: { user_role: "store_staff" }
      }
    end

    @account_user.reload
    refute @account_user.archived?
    assert_equal "store_staff", @account_user.user_role
  end
end
