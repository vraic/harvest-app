require "application_system_test_case"

class OrderDetailsTest < ApplicationSystemTestCase
  setup do
    @customer_user = users(:three)
    @staff_user = users(:one)
    @order = orders(:one)
    @order.update!(location: locations(:one))

    # Ensure order has some items
    if @order.order_items.empty?
      @order.order_items.create!(inventory_item: inventory_items(:one), quantity: 2, price: 10.00, location: locations(:one))
      @order.calculate_total
      @order.save!
    end
  end

  test "customer can view order details" do
    login_as @customer_user
    visit order_path(@order)

    assert_text "Order ##{@order.number}"
    assert_text "STATUS"
    assert_text @order.status.titleize
    assert_text "COLLECTION POINT"
    assert_text @order.location.name

    # Items
    assert_text "Items"
    @order.order_items.each do |item|
      assert_text item.inventory_item.display_name
      assert_text "Qty #{item.quantity}"
    end

    # Summary
    assert_text "CUSTOMER"
    assert_text @order.customer.name
    assert_text "PAYMENT"
    assert_text "Total"
    assert_text "£10"

    # Should not see staff actions
    assert_no_text "STAFF ACTIONS"
    assert_no_text "NOTES"
    assert_no_button "Mark as Ready"
  end

  test "staff can view and manage order details" do
    login_as @staff_user
    # Ensure we are in the right account context if needed, but OrderPolicy scope should handle it
    visit order_path(@order)

    assert_text "Order ##{@order.number}"
    assert_text "STAFF ACTIONS"

    if @order.ordered?
      assert_button "Mark as Ready"
      click_on "Mark as Ready"
      assert_text "Ready for Collection"
    end

    # Notes
    assert_text "NOTES"
    fill_in "Add staff note...", with: "This is a test note"
    click_on "Save Note"
    assert_text "This is a test note"
    assert_text @staff_user.name
  end
end
