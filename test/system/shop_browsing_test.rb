require "application_system_test_case"

class ShopBrowsingTest < ApplicationSystemTestCase
  setup do
    @user = users(:one) # A customer user
    # Ensure they have no memberships for some stores
    ActsAsTenant.without_tenant do
      @user.account_users.where.not(account: accounts(:one)).destroy_all
      @user.customers.where.not(account: accounts(:one)).destroy_all
    end
    login_as(@user)
  end

  test "can see all stores produce without joining" do
    visit shop_path

    # Should see categories/products from accounts they haven't joined
    assert_text "Account Two"
    assert_text "Account Three"
  end

  test "can filter by store" do
    visit shop_path

    select "Account Two", from: "Store"
    click_on "Filter"

    # Use match: :prefer_exact to handle the extra query params
    assert_current_path(/account_id=#{accounts(:two).id}/)
    assert_text "Search Results"
    assert_text "Account Two"
  end

  test "can filter by price" do
    visit shop_path

    fill_in "Min Price (£)", with: "5"
    fill_in "Max Price (£)", with: "15"
    click_on "Filter"

    assert_text "Search Results"
  end

  test "can add item from unjoined store and checkout" do
    visit shop_path

    # Target the featured products section to avoid category cards
    within "#featured-products" do
      within "div.group", text: "Account Two", match: :first do
        click_on "Add to cart"
      end
    end

    assert_text "added to cart"

    visit checkout_path

    assert_text "Account Two"
    # Select collection point (required)
    select "Main Warehouse", from: "checkout[#{accounts(:two).id}][location_id]"

    click_on "Place Orders"

    assert_text "Orders successfully created"

    # Verify Customer record was created
    ActsAsTenant.without_tenant do
      assert Customer.exists?(user: @user, account: accounts(:two))
    end
  end
end
