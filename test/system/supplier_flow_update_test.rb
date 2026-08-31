require "application_system_test_case"

class SupplierFlowUpdateTest < ApplicationSystemTestCase
  setup do
    @admin = users(:one) # Global admin
    @manager = User.create!(name: "Store Manager", email_address: "manager@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")
    @staff = User.create!(name: "Store Staff", email_address: "staff@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")

    @account = Account.create!(name: "New Fresh Store", owner: @manager)
    AccountUser.create!(account: @account, user: @staff, user_role: :store_staff)

    @other_account = accounts(:two)
  end

  test "sidebar no longer has Supply Stores link" do
    login_as(@manager)
    visit dashboard_path

    within "#desktop-sidebar-main-nav" do
      assert_no_text "Supply Stores"
    end
  end

  test "manager can access Stores We Supply tab and send a request" do
    login_as(@manager)

    # Account should be auto-selected since it's the only one
    visit dashboard_path

    visit edit_account_path(@account)

    assert_text "General"
    assert_text "Stores We Supply"

    click_on "Stores We Supply"

    assert_text "You are not currently supplying any other stores."
    click_on "Supply A Store"

    assert_text "Apply as Supplier"
    assert_text "Applying from Store"
    assert_text @account.name

    select @other_account.name, from: "Applying to Supply"
    click_on "Send Supplier Request"

    assert_text "Request sent"

    # Go back to edit account to see it in the table
    visit edit_account_path(@account, tab: "stores_we_supply")
    assert_text @other_account.name
    assert_text "Pending Approval"
  end

  test "staff cannot access account edit page" do
    login_as(@staff)

    # Account should be auto-selected since it's the only one
    visit dashboard_path

    # Try to visit edit page
    visit edit_account_path(@account)

    # Should be redirected with unauthorized
    assert_text "Not authorized"
    assert_current_path dashboard_path
  end

  test "account new page shows Stores We Supply tab but disabled" do
    login_as(@admin)
    visit new_account_path

    assert_text "General"
    assert_text "Stores We Supply"
    # The tab should be a span, not a link
    assert_selector "span", text: "Stores We Supply"
    assert_no_link "Stores We Supply"
  end
end
