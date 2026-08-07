require "test_helper"

class OrderFlowTest < ActionDispatch::IntegrationTest
  setup do
    @staff = users(:one) # Admin in account one
    @customer_user = users(:three) # Customer in account one
    @customer_record = customers(:one)
    @item = inventory_items(:one)
    @location = locations(:one)
  end

  test "staff can create an order for a customer" do
    sign_in_as(@staff)

    assert_difference -> { Order.count } => 1, -> { OrderItem.count } => 1 do
      post orders_url, params: {
        order: {
          customer_id: @customer_record.id,
          status: "ordered",
          order_items_attributes: [
            { inventory_item_id: @item.id, location_id: @location.id, quantity: 2, price: 10.50 }
          ]
        }
      }
    end

    order = Order.last
    assert_redirected_to order_url(order)
    assert_equal @staff, order.user
    assert_equal 2100, order.total_amount_cents
  end

  test "customer can create their own order" do
    sign_in_as(@customer_user)

    assert_difference -> { Order.count } => 1, -> { OrderItem.count } => 1, -> { Payment.count } => 1 do
      post orders_url, params: {
        order: {
          payment_method: "cash_on_collection",
          location_id: @location.id,
          order_items_attributes: [
            { inventory_item_id: @item.id, location_id: @location.id, quantity: 1, price: 15.00 }
          ]
        }
      }
    end

    order = Order.last
    assert_equal @customer_record, order.customer
    assert_nil order.user # No staff assigned initially
    assert_equal "cash_on_collection", order.payment.payment_method
    assert_equal "pending", order.payment.status
  end

  test "customer can pay via gocardless once they have configured mandate" do
    sign_in_as(@customer_user)
    @customer_record.update!(gocardless_customer_id: "GC-CUST-001", gocardless_mandate_id: "MD0001", gocardless_configured_at: Time.current)

    assert_difference -> { Order.count } => 1, -> { OrderItem.count } => 1, -> { Payment.count } => 1 do
      post orders_url, params: {
        order: {
          payment_method: "gocardless",
          location_id: @location.id,
          order_items_attributes: [
            { inventory_item_id: @item.id, location_id: @location.id, quantity: 1, price: 15.00 }
          ]
        }
      }
    end

    order = Order.last
    assert_equal "gocardless", order.payment.payment_method
    assert_equal "pending", order.payment.status
    assert_equal "MD0001", order.payment.provider_reference
  end

  test "customer cannot pay via gocardless before mandate setup" do
    sign_in_as(@customer_user)

    assert_no_difference [ "Order.count", "OrderItem.count", "Payment.count" ] do
      post orders_url, params: {
        order: {
          payment_method: "gocardless",
          location_id: @location.id,
          order_items_attributes: [
            { inventory_item_id: @item.id, location_id: @location.id, quantity: 1, price: 15.00 }
          ]
        }
      }
    end

    assert_response :unprocessable_content
    assert_match "GoCardless setup is required", response.body
  end

  test "unauthorized user cannot see orders" do
    sign_in_as(users(:two)) # Different account
    get orders_url
    assert_response :success
    assert_select "td", text: "No orders found." # Should be empty due to policy scope
  end
end
