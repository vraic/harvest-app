require "application_system_test_case"

class CustomerOrdersTest < ApplicationSystemTestCase
  setup do
    @customer_user = users(:three)
    @account = accounts(:one)
    @item = inventory_items(:one)
    @location = locations(:one)
  end

  test "customer can shop and checkout" do
    login_as @customer_user

    # Go to shop (unified view)
    visit shop_path
    assert_text "Shop by Category"

    # Quick add to cart from shop page
    # Find the link to the product and then the add to cart button in the same card
    find("h3", text: @item.display_name).find(:xpath, "ancestor::div[contains(@class, 'group')][1]").click_on "Add to cart"
    assert_text "#{@item.name} added to cart"

    # Verify cart count in header
    assert_text "1"

    # Go to cart
    visit cart_path
    assert_text "Shopping Cart"
    assert_text @item.display_name
    assert_text @account.name

    # Proceed to checkout
    click_on "Checkout"

    assert_current_path checkout_path

    # Choose collection point for the specific account
    # Select by ID because names might be ambiguous across shops
    select @location.name, from: "checkout[#{@account.id}][location_id]"

    # Choose payment method
    select "Cash on collection", from: "payment_method"

    click_on "Place Orders"

    assert_text "Orders successfully created"

    order = Order.last
    assert_equal @customer_user.customers.find_by(account: @account), order.customer
    assert_equal @location, order.location
    assert_equal "cash_on_collection", order.payment.payment_method
  end

  test "customer can shop and checkout from multiple stores" do
    # User 3 is already a customer of Account 1
    # Let's make them a customer of Account 2 as well
    AccountUser.create!(user: @customer_user, account: accounts(:two), user_role: :customer)
    Customer.create!(user: @customer_user, account: accounts(:two), name: @customer_user.name, email_address: @customer_user.email_address)

    # And a collection point for Account 2
    loc2 = Location.create!(account: accounts(:two), name: "Store Two Collection", collection_point: true)

    # And an item for Account 2
    ig2 = InventoryGroup.create!(account: accounts(:two), name: "Store Two Group")
    item_two = InventoryItem.create!(account: accounts(:two), inventory_group: ig2, name: "Store Two Item", price_cents: 1000)
    InventoryLevel.create!(account: accounts(:two), inventory_item: item_two, location: loc2, quantity: 10)

    login_as @customer_user

    visit shop_path

    # Add item from Account 1
    find("h3", text: @item.display_name).find(:xpath, "ancestor::div[contains(@class, 'group')][1]").click_on "Add to cart"
    assert_text "#{@item.name} added to cart"

    # Add item from Account 2
    find("h3", text: item_two.display_name).find(:xpath, "ancestor::div[contains(@class, 'group')][1]").click_on "Add to cart"
    assert_text "#{item_two.name} added to cart"

    visit cart_path
    assert_text "2"
    assert_text accounts(:one).name
    assert_text accounts(:two).name

    click_on "Checkout"

    # Fill in for Account 1
    select @location.name, from: "checkout[#{@account.id}][location_id]"

    # Fill in for Account 2
    select "Store Two Collection", from: "checkout[#{accounts(:two).id}][location_id]"

    # Choose payment method
    select "Cash on collection", from: "payment_method"

    assert_difference "Order.count", 2 do
      click_on "Place Orders"
      assert_text "Orders successfully created"
    end

    order1 = Order.find_by(account: @account)
    order2 = Order.find_by(account: accounts(:two))

    assert_not_nil order1
    assert_not_nil order2
    assert_equal "Store Two Collection", order2.location.name

    # Visit order show page to verify the new template
    visit order_path(order1)
    assert_text "Order ##{order1.number}"
    assert_text @item.display_name
    assert_text "Ordered"
  end

  test "customer can edit item quantity in cart" do
    login_as @customer_user

    # Add item
    visit shop_path
    find("h3", text: @item.display_name).find(:xpath, "ancestor::div[contains(@class, 'group')][1]").click_on "Add to cart"
    assert_text "#{@item.name} added to cart"

    # Go to cart
    visit cart_path
    within("#desktop-cart-count") do
      assert_text "1"
    end

    # Change quantity
    select "3", from: "quantity_#{@item.id}"

    # Turbo update should happen
    assert_text "Cart updated"
    assert_text "3"

    # Total price should update (item price is 10.00 in fixtures usually, or whatever it is)
    # We can check the count in the header too
    within("#desktop-cart-count") do
      assert_text "3"
    end
  end
end
