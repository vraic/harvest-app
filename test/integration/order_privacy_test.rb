require "test_helper"

class OrderPrivacyTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @manager = users(:one)

    # Create two users who are just customers
    @user_a = User.create!(
      name: "User A",
      email_address: "user_a@example.com",
      password: "Password123!@#ABC",
      onboarded: true
    )
    @user_b = User.create!(
      name: "User B",
      email_address: "user_b@example.com",
      password: "Password123!@#ABC",
      onboarded: true
    )

    ActsAsTenant.with_tenant(@account) do
      # Link them to @account
      AccountUser.create!(account: @account, user: @user_a, user_role: :customer)
      AccountUser.create!(account: @account, user: @user_b, user_role: :customer)

      # Create customer records
      @customer_record_a = Customer.create!(
        account: @account,
        user: @user_a,
        name: @user_a.name,
        email_address: @user_a.email_address
      )
      @customer_record_b = Customer.create!(
        account: @account,
        user: @user_b,
        name: @user_b.name,
        email_address: @user_b.email_address
      )

      # Create an order for Customer A
      @order_a = Order.create!(
        customer: @customer_record_a,
        location: locations(:one),
        total_amount_cents: 1000,
        number: "111AAA"
      )
    end
  end

  test "customer cannot see another customer's orders in the same store" do
    # Log in as User B
    sign_in_as @user_b

    # Switch to the account context
    patch managed_account_url(account_id: @account.id)

    # Try to access Customer A's order directly
    get order_url(@order_a)
    assert_redirected_to root_path

    # Try to see it in the index
    get orders_url
    assert_response :success
    assert_no_match @order_a.number, response.body
  end

  test "customer can see their own orders" do
    # Log in as User A
    sign_in_as @user_a

    # Switch to the account context
    patch managed_account_url(account_id: @account.id)

    # Access their own order
    get order_url(@order_a)
    assert_response :success
    assert_match @order_a.number, response.body

    # See it in the index
    get orders_url
    assert_response :success
    assert_match @order_a.number, response.body
  end
end
