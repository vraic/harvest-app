require "application_system_test_case"

class OrderSearchTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @order_one = orders(:one)
    @order_two = orders(:two)
    grant_support_access(accounts(:one))
  end

  test "searching by customer name" do
    login_as @admin
    select_account("Account One")
    visit orders_url

    fill_in "query", with: "Customer One"
    within "#order-search-form" do
      click_on "Search"
    end

    assert_text "Customer One"
  end

  test "searching by customer email" do
    login_as @admin
    select_account("Account One")
    visit orders_url

    fill_in "query", with: "customer@example.com"
    within "#order-search-form" do
      click_on "Search"
    end

    assert_text "Customer One"
  end

  test "searching by order id" do
    login_as @admin
    select_account("Account One")
    visit orders_url

    fill_in "query", with: @order_one.number
    within "#order-search-form" do
      click_on "Search"
    end

    assert_text @order_one.number
    assert_no_text @order_two.number
  end

  test "searching by total cents" do
    login_as @admin
    select_account("Account One")
    visit orders_url

    fill_in "query", with: "1000"
    within "#order-search-form" do
      click_on "Search"
    end

    assert_text "£10.00"
    assert_no_text "£20.00"
  end

  test "searching by total decimal" do
    login_as @admin
    select_account("Account One")
    visit orders_url

    fill_in "query", with: "10.00"
    within "#order-search-form" do
      click_on "Search"
    end

    assert_text "£10.00"
    assert_no_text "£20.00"
  end

  test "clearing search" do
    login_as @admin
    select_account("Account One")
    visit orders_url

    fill_in "query", with: @order_one.number
    within "#order-search-form" do
      click_on "Search"
    end

    assert_no_text @order_two.number

    click_on "Clear"

    assert_text @order_one.number
    assert_text @order_two.number
  end
end
