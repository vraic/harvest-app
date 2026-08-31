require "test_helper"

class InventoryManagementTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @item = inventory_items(:one)
    @location = locations(:one)
    sign_in_as(@user)
  end

  test "can adjust stock level for an item" do
    get inventory_item_path(@item)
    assert_response :success
    assert_select "h2", "Adjust Stock"

    assert_difference -> { InventoryLevel.find_by(inventory_item: @item, location: @location).quantity } => 15 do
      post inventory_item_inventory_levels_path(@item), params: {
        location_id: @location.id,
        quantity: 25 # Fixture has 10
      }
    end

    assert_redirected_to inventory_item_path(@item)
    follow_redirect!
    assert_match "Stock adjusted", response.body
    assert_match "25 units", response.body # Ribeye is per unit in fixture one
  end

  test "can transfer stock between locations" do
    to_location = locations(:two)
    # Ensure there is stock to transfer
    @item.inventory_levels.find_or_create_by!(location: @location, quantity: 10, account: @user.accounts.first)

    get inventory_item_path(@item)
    assert_select "h2", "Transfer Stock"

    assert_difference -> { InventoryLevel.find_by(inventory_item: @item, location: @location).quantity } => -5,
                      -> { InventoryLevel.find_or_initialize_by(inventory_item: @item, location: to_location).quantity } => 5 do
      post transfer_inventory_item_inventory_levels_path(@item), params: {
        from_location_id: @location.id,
        to_location_id: to_location.id,
        transfer_quantity: 5
      }
    end

    assert_redirected_to inventory_item_path(@item)
    follow_redirect!
    assert_match "Stock transferred", response.body
  end
end
