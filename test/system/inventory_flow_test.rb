require "application_system_test_case"

class InventoryFlowTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    grant_support_access(accounts(:one))
    login_as @admin
  end

  test "creating a parent item, then a variant, and adjusting stock" do
    select_account("Account One")

    visit inventory_items_url
    assert_selector "h1", text: "Inventory"
    click_on "New Item"

    assert_selector "h1", text: "New inventory item"
    fill_in "inventory_item_name", with: "Test Product"
    fill_in "inventory_item_description", with: "Product description"
    fill_in "inventory_item_price", with: "19.99"
    select "Meat", from: "Group"
    click_button "Create Inventory item"

    assert_text "Item created"
    assert_text "Test Product"
    assert_text "£19.99"

    parent = InventoryItem.find_by!(name: "Test Product")
    click_on "Add Variant"

    assert_selector "h1", text: "New inventory item"
    fill_in "inventory_item_name", with: "Small Pack"
    fill_in "inventory_item_price", with: "9.99"
    select "Per weight", from: "Pricing Unit"
    fill_in "inventory_item_weight_value", with: "250"
    fill_in "inventory_item_weight_unit", with: "g"
    click_button "Create Inventory item"

    assert_text "Item created"
    assert_text "Small Pack"
    assert_text "£9.99"

    # Adjust stock
    select "Storage Room", from: "Location"
    fill_in "New Total Quantity", with: "50"
    click_on "Update Stock"

    assert_text "Stock adjusted"
    assert_text "50"

    # Move stock
    select "Storage Room", from: "From Location"
    select "Shop Floor", from: "To Location"
    fill_in "Quantity to Move", with: "10"
    click_on "Transfer"

    assert_text "Stock transferred"
    assert_text "40" # Remaining in Storage Room
    assert_text "10" # New on Shop Floor
  end

  private
end
