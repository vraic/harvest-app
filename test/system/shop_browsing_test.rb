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

  test "customer cannot see a store in shop when b2c is turned off" do
    customer_user = users(:three)
    account = accounts(:two)
    original_b2c = account.is_b2c
    account.update!(is_b2c: false)

    login_as(customer_user)
    visit shop_path

    assert_no_text "Account Two"
  ensure
    account.update!(is_b2c: original_b2c)
  end

  test "supplier operator cannot see b2b-only store without supplier authorization" do
    supplier_user = users(:two)
    supplier_account = accounts(:two)
    b2b_store = accounts(:four)
    original_b2c = b2b_store.is_b2c
    original_b2b = b2b_store.is_b2b
    b2b_store.update!(is_b2c: false, is_b2b: true)

    login_as(supplier_user)
    visit shop_path

    assert_no_text b2b_store.name
    refute_selector "option", text: b2b_store.name
  ensure
    b2b_store.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end

  test "supplier operator can see authorized b2b-only store" do
    supplier_user = users(:two)
    supplier_account = accounts(:two)
    b2b_store = accounts(:four)
    original_b2c = b2b_store.is_b2c
    original_b2b = b2b_store.is_b2b
    b2b_store.update!(is_b2c: false, is_b2b: true)

    supplier_link = ActsAsTenant.without_tenant do
      Supplier.create!(
        account: b2b_store,
        supplier_account: supplier_account,
        name: supplier_account.name,
        email_address: "shop-authorized-supplier@example.com"
      )
    end

    login_as(supplier_user)
    visit shop_path

    assert_text b2b_store.name
    assert_selector "option", text: b2b_store.name
  ensure
    supplier_link&.destroy!
    b2b_store.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end
end
