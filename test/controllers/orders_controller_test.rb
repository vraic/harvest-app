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
