require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "calculates total correctly" do
    order = Order.new(account: accounts(:one), customer: customers(:one))
    order.order_items.build(inventory_item: inventory_items(:one), quantity: 2, price_cents: 1000)
    order.order_items.build(inventory_item: inventory_items(:two), quantity: 1, price_cents: 500)
    order.valid?
    assert_equal 2500, order.total_amount_cents
  end

  test "sends email on creation" do
    assert_enqueued_emails 1 do
      Order.create!(account: accounts(:one), customer: customers(:one), location: locations(:one), status: :ordered)
    end
  end

  test "sends email when status changes to awaiting_collection" do
    order = orders(:one)
    assert_enqueued_emails 1 do
      order.awaiting_collection!
    end
  end
end
