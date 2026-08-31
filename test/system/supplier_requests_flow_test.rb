require "application_system_test_case"

class SupplierRequestsFlowTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    grant_support_access(accounts(:one))
    grant_support_access(accounts(:two))
    login_as @admin
  end

  test "requesting to supply another store via edit account" do
    # 1. Select the account that wants to be a supplier
    select_account("Account One")

    visit edit_account_path(accounts(:one))
    click_link "Stores We Supply"
    click_link "Supply A Store"

    assert_text "Apply as Supplier"
    assert_text "Applying to Supply"
    assert_text "Applying from Store"
    assert_text "Account One"

    select "Account Two", from: "Applying to Supply"
    click_on "Send Supplier Request"

    assert_text "Request sent"

    # Verify the request exists
    request = SupplierRequest.last
    assert_equal accounts(:one), request.sender_account
    assert_equal accounts(:two), request.receiver_account
    assert_equal "pending", request.status
  end

  test "can see supply tab if manager" do
    @user = users(:one)
    login_as @user
    visit edit_account_path(accounts(:one))
    assert_text "Stores We Supply"
  end

  test "approved supplier request shows up in both tabs for appropriate accounts" do
    # 1. Account One requests to supply Account Two
    select_account("Account One")
    visit new_supplier_request_path

    select "Account Two", from: "Applying to Supply"
    click_on "Send Supplier Request"

    assert_text "Request sent"

    # 2. Account Two approves the request
    select_account("Account Two")
    visit supplier_requests_path
    # Find the row in the supplier requests table, not the sidebar/banner
    within "#supplier_requests" do
      within find("tr", text: "Account One") do
        click_on "Approve"
      end
    end
    assert_text "Request approved"

    # 3. Check Suppliers in Account Two (Account One should be there as a supplier)
    visit suppliers_path
    within "#suppliers" do
      assert_text "Account One"
    end

    # 4. Check Customers in Account One (Account Two should be there as a business customer)
    select_account("Account One")
    visit customers_path
    within "#customers" do
      assert_text "Account Two"
      assert_text "Business"
    end
  end
end
