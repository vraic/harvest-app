require "application_system_test_case"

class SupplierSearchTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @supplier_one = suppliers(:one)
    @supplier_two = suppliers(:two)
    grant_support_access(accounts(:one))
  end

  test "searching by supplier name" do
    login_as @admin
    select_account("Account One")
    visit suppliers_url

    fill_in "query", with: "Supplier One"
    within "#supplier-search-form" do
      click_on "Search"
    end

    assert_text "Supplier One"
    assert_no_text "Supplier Two"
  end

  test "searching by email" do
    login_as @admin
    select_account("Account One")
    visit suppliers_url

    fill_in "query", with: @supplier_one.email_address
    within "#supplier-search-form" do
      click_on "Search"
    end

    assert_text @supplier_one.name
    assert_no_text "Supplier Two"
  end

  test "searching by phone" do
    login_as @admin
    select_account("Account One")
    visit suppliers_url

    fill_in "query", with: @supplier_one.phone
    within "#supplier-search-form" do
      click_on "Search"
    end

    assert_text @supplier_one.name
    assert_no_text "Supplier Two"
  end

  test "clearing search" do
    login_as @admin
    select_account("Account One")
    visit suppliers_url

    fill_in "query", with: "Supplier One"
    within "#supplier-search-form" do
      click_on "Search"
    end

    assert_no_text "Supplier Two"

    click_on "Clear"

    assert_text "Supplier One"
  end
end
