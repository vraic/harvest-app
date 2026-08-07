require "application_system_test_case"

class InventorySearchTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @item_one = inventory_items(:one)
    @item_apple = inventory_items(:apple)
    grant_support_access(accounts(:one))
  end

  test "searching by name" do
    login_as @admin
    select_account("Account One")
    visit inventory_items_url

    fill_in "query", with: "Ribeye"
    within "#inventory-search-form" do
      click_on "Search"
    end

    assert_text "Ribeye Steak"
    assert_no_text "Braeburn Apple"
  end

  test "searching by partial name" do
    login_as @admin
    select_account("Account One")
    visit inventory_items_url

    fill_in "query", with: "Apple"
    within "#inventory-search-form" do
      click_on "Search"
    end

    assert_text "Braeburn Apple"
    assert_no_text "Ribeye Steak"
  end

  test "searching by description" do
    login_as @admin
    select_account("Account One")
    visit inventory_items_url

    fill_in "query", with: "grass-fed"
    within "#inventory-search-form" do
      click_on "Search"
    end

    assert_text "Ribeye Steak"
    assert_no_text "Braeburn Apple"
  end

  test "searching by inventory group" do
    login_as @admin
    select_account("Account One")
    visit inventory_items_url

    fill_in "query", with: "Fruit"
    within "#inventory-search-form" do
      click_on "Search"
    end

    assert_text "Braeburn Apple"
    assert_no_text "Ribeye Steak"
  end

  test "clearing search" do
    login_as @admin
    select_account("Account One")
    visit inventory_items_url

    fill_in "query", with: "Ribeye"
    within "#inventory-search-form" do
      click_on "Search"
    end

    assert_no_text "Braeburn Apple"

    click_on "Clear"

    assert_text "Ribeye Steak"
    assert_text "Braeburn Apple"
  end

  test "searching for a variant shows the parent" do
    login_as @admin
    select_account("Account One")
    visit inventory_items_url

    fill_in "query", with: "500g"
    within "#inventory-search-form" do
      click_on "Search"
    end

    assert_text "Ribeye Steak"
  end
end
