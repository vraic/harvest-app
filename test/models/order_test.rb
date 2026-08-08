require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "notifies active staff for customer orders" do
    account = accounts(:one)
    manager = users(:one)
    staff_user = users(:two)
    customer_user = users(:three)

    AccountUser.find_or_create_by!(account: account, user: staff_user) { |au| au.user_role = :store_staff }
    AccountUser.find_or_create_by!(account: account, user: customer_user) { |au| au.user_role = :customer }

    assert_difference(-> { manager.notifications.count }, 1) do
      assert_difference(-> { staff_user.notifications.count }, 1) do
        assert_no_difference(-> { customer_user.notifications.count }) do
          Order.create!(account: account, customer: customers(:one), location: locations(:one), status: :ordered)
        end
      end
    end
  end

  test "does not notify staff for internal orders" do
    account = accounts(:one)
    manager = users(:one)
    staff_user = users(:two)

    AccountUser.find_or_create_by!(account: account, user: staff_user) { |au| au.user_role = :store_staff }

    assert_no_difference(-> { manager.notifications.count }) do
      assert_no_difference(-> { staff_user.notifications.count }) do
        Order.create!(
          account: account,
          customer: customers(:one),
          location: locations(:one),
          status: :ordered,
          user: manager
        )
      end
    end
  end

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
