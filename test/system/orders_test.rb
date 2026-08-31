require "application_system_test_case"

class OrdersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @item = inventory_items(:one) # Ribeye Steak, 19.99, 10 units in Storage Room
    @location = locations(:one) # Storage Room
    grant_support_access(accounts(:one))
  end

  test "staff member sees auto-filled price and stock limit" do
    login_as @admin

    select_account("Account One")

    visit new_order_url

    # Select customer
    select "Customer One", from: "Customer"

    # Use the initial item row built by the controller
    assert_selector ".nested-form-wrapper", count: 1
    within ".nested-form-wrapper" do
      # Select product
      select @item.display_name, from: "Product"

      # Check if price is auto-filled
      assert_field "Unit Price", with: "19.99"

      # Select location
      select @location.name, from: "Location"

      # Check if quantity max is set to 10
      assert_selector "input[name*='quantity'][max='10']"

      # Change quantity to 5
      fill_in "Quantity", with: "5"
    end

    click_on "Create Order"

    assert_text "Order created"
  end

  private
end
