require "test_helper"

class ReferralFlowTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @account.referral_codes.create(code: "storeone")
    @user = User.create!(name: "New User", email_address: "newuser@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")
  end

  test "user landing on dashboard with referral cookie is associated as customer" do
    # Simulate landing on a referral link
    # get root_path(ref: "storeone")
    # assert_response :success

    # Manually set the signed cookie as the gem would do
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:referral] = "storeone"
      cookies[:referral] = cookie_jar[:referral]
    end

    # Sign in
    post session_path, params: { email_address: @user.email_address, password: "Password123!@#Strong" }
    follow_redirect! # two factor

    sign_in_as(@user)

    get dashboard_path
    assert_response :success

    customer = Customer.find_by(account: @account, user: @user)
    assert_not_nil customer, "Customer should have been created"
    assert_equal "Joined account", flash[:notice]
  end
end
