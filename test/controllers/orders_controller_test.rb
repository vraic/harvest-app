require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:one)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get orders_url
    assert_response :success
    assert_select "main > div > div.w-full", count: 1
  end

  test "should filter orders by today" do
    account = @order.account
    customer = @order.customer

    # Create an order from today
    today_order = Order.create!(
      account: account,
      customer: customer,
      location: locations(:one),
      total_amount_cents: 1000,
      status: :ordered,
      created_at: Time.current
    )

    # Create an order from yesterday
    yesterday_order = Order.create!(
      account: account,
      customer: customer,
      location: locations(:one),
      total_amount_cents: 2000,
      status: :ordered,
      created_at: 1.day.ago
    )

    get orders_url(filter: "today")
    assert_response :success
    assert_select "td", text: /#{today_order.number}/
    assert_select "td", text: /#{yesterday_order.number}/, count: 0
  end

  test "should get new" do
    get new_order_url
    assert_response :success
  end

  test "should create order" do
    assert_difference("Order.count") do
      post orders_url, params: { order: { customer_id: @order.customer_id, notes: @order.notes, status: @order.status } }
    end

    assert_redirected_to order_url(Order.last)
  end

  test "customer cannot access new order when storefront is disabled" do
    sign_out
    sign_in_as(users(:three))

    account = accounts(:one)
    original_b2c = account.is_b2c
    original_b2b = account.is_b2b
    account.update!(is_b2c: false, is_b2b: false)

    get new_order_url

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match "This store is not available for customer shopping.", response.body
  ensure
    account.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end

  test "customer cannot create order when storefront is disabled" do
    sign_out
    sign_in_as(users(:three))

    account = accounts(:one)
    original_b2c = account.is_b2c
    original_b2b = account.is_b2b
    account.update!(is_b2c: false, is_b2b: false)

    assert_no_difference("Order.count") do
      post orders_url, params: { order: { notes: "Blocked storefront order" } }
    end

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match "This store is not available for customer shopping.", response.body
  ensure
    account.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end

  test "supplier operator cannot access b2b order flow without supplier authorization" do
    sign_out
    operator_user = users(:two)
    sign_in_as(operator_user)

    supplier_store = accounts(:four)
    original_b2c = supplier_store.is_b2c
    original_b2b = supplier_store.is_b2b
    supplier_store.update!(is_b2c: false, is_b2b: true)

    customer_membership = ActsAsTenant.without_tenant do
      AccountUser.create!(account: supplier_store, user: operator_user, user_role: :customer)
    end

    session = Current.session
    patch managed_account_path, params: { account_id: supplier_store.id }

    assert_no_difference("Order.count") do
      post orders_url, params: { order: { notes: "Unauthorized supplier order" } }
    end

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match "This store is not available for customer shopping.", response.body
  ensure
    Current.session = session if defined?(session) && session
    customer_membership&.destroy!
    supplier_store.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end

  test "supplier operator can access b2b order flow when authorized as supplier" do
    sign_out
    operator_user = users(:two)
    sign_in_as(operator_user)

    operator_account = accounts(:two)
    supplier_store = accounts(:four)
    original_b2c = supplier_store.is_b2c
    original_b2b = supplier_store.is_b2b
    supplier_store.update!(is_b2c: false, is_b2b: true)

    customer_membership = ActsAsTenant.without_tenant do
      AccountUser.create!(account: supplier_store, user: operator_user, user_role: :customer)
    end
    supplier_authorization = ActsAsTenant.without_tenant do
      Supplier.create!(
        account: supplier_store,
        supplier_account: operator_account,
        name: operator_account.name,
        email_address: "authorized-supplier-order@example.com"
      )
    end

    session = Current.session
    patch managed_account_path, params: { account_id: supplier_store.id }

    get new_order_url
    assert_response :success
  ensure
    Current.session = session if defined?(session) && session
    supplier_authorization&.destroy!
    customer_membership&.destroy!
    supplier_store.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end

  test "should show order" do
    get order_url(@order)
    assert_response :success
  end

  test "should get edit" do
    get edit_order_url(@order)
    assert_response :success
  end

  test "should update order" do
    patch order_url(@order), params: { order: { notes: "Updated notes" } }
    assert_redirected_to order_url(@order)
  end

  test "should destroy order" do
    assert_difference("Order.count", -1) do
      delete order_url(@order)
    end

    assert_redirected_to orders_url
  end
end
