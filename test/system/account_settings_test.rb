require "application_system_test_case"

class AccountSettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
    # Ensure user is manager
    AccountUser.find_or_create_by!(account: @account, user: @user, user_role: :store_manager)
    login_as(@user)
  end

  test "updating GoCardless settings" do
    visit edit_account_path(@account)

    click_on "Payments"

    fill_in "Access Token", with: "live_12345678"
    choose "Production", allow_label_click: true

    click_on "Save Payment Settings"

    assert_text "Account updated"

    @account.reload
    assert_equal "live_12345678", @account.gocardless_access_token
    assert @account.production?

    # Verify values are persisted in the form
    visit edit_account_path(@account)
    click_on "Payments"
    assert_field "Access Token", with: "live_12345678"
    assert_checked_field "Production"
  end

  test "store manager can access staff tab" do
    visit edit_account_path(@account)

    assert_link "Staff"
    click_on "Staff"

    assert_text "Active Staff"
    assert_link "Invite User"
  end

  test "non-manager cannot access staff tab" do
    login_as(users(:three))

    visit edit_account_path(@account, tab: "staff")

    assert_text I18n.t("unauthorized")
    assert_current_path shop_path
  end

  test "validation failure keeps user on the correct tab" do
    visit edit_account_path(@account)

    click_on "Payments"

    # Trigger validation failure (minimum 8 chars)
    fill_in "Access Token", with: "short"

    click_on "Save Payment Settings"

    assert_text "Gocardless access token is too short"
    # Ensure we are still on the Payments tab
    assert_selector "h2", text: "GoCardless Configuration"
    assert_field "Access Token", with: "short"
  end

  test "updating store retention settings" do
    visit edit_account_path(@account)

    click_on "Data Retention"

    fill_in "Inactive record retention (years)", with: 8
    fill_in "Archived record purge window (days)", with: 180
    select "Archive record", from: "Inactive customer action"
    select "Do nothing (manual review)", from: "Inactive supplier action"

    click_on "Save Retention Settings"

    assert_text "Account updated"

    @account.reload
    assert_equal 8, @account.inactivity_retention_years_override
    assert_equal 180, @account.soft_delete_retention_days_override
    assert_equal "archive", @account.inactive_customer_retention_action
    assert_equal "none", @account.inactive_supplier_retention_action
  end

  test "account settings tabs use consistent panel and table styles" do
    visit edit_account_path(@account)

    [ "General", "Loyalty Program", "Payments", "Data Retention", "Stores We Supply", "Staff" ].each do |tab_name|
      click_on tab_name

      assert_selector :xpath, "//div[contains(@class,'rounded-lg') and contains(@class,'bg-white') and contains(@class,'dark:bg-gray-800')]"
      assert_selector :xpath, "//table[contains(@class,'min-w-full') and contains(@class,'divide-y')]" if [ "Stores We Supply", "Staff" ].include?(tab_name)
    end
  end
end
