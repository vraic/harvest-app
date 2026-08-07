require "application_system_test_case"

class CustomerSearchTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @customer_one = customers(:one)
    @customer_two = customers(:two)
    grant_support_access(accounts(:one))
    grant_support_access(accounts(:four))
  end

  test "searching by customer name" do
    login_as @admin
    select_account("Account One")
    visit customers_url

    fill_in "query", with: "Customer One"
    within "#customer-search-form" do
      click_on "Search"
    end

    assert_text "Customer One"
    assert_no_text "Customer Two"
  end

  test "searching by email" do
    login_as @admin
    select_account("Account One")
    visit customers_url

    fill_in "query", with: @customer_one.email_address
    within "#customer-search-form" do
      click_on "Search"
    end

    assert_text @customer_one.name
    assert_no_text "Customer Two"
  end

  test "searching by phone" do
    login_as @admin
    select_account("Account One")
    visit customers_url

    fill_in "query", with: @customer_one.phone
    within "#customer-search-form" do
      click_on "Search"
    end

    assert_text @customer_one.name
    assert_no_text "Customer Two"
  end

  test "clearing search" do
    login_as @admin
    select_account("Account One")
    visit customers_url

    fill_in "query", with: "Customer One"
    within "#customer-search-form" do
      click_on "Search"
    end

    assert_no_text "Customer Two"

    click_on "Clear"

    assert_text "Customer One"
    # Note: Customer Two might not be visible if we are scoped to Account One
    # In Account One there is only Customer One (from fixtures)
  end

  test "searching by business account name" do
    login_as @admin
    select_account("Account Four")
    visit customers_url

    fill_in "query", with: "Account One"
    within "#customer-search-form" do
      click_on "Search"
    end

    assert_text "Business Customer"
  end
end
