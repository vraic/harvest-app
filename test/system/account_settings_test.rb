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

    assert_text "Account was successfully updated."

    @account.reload
    assert_equal "live_12345678", @account.gocardless_access_token
    assert @account.production?

    # Verify values are persisted in the form
    visit edit_account_path(@account)
    click_on "Payments"
    assert_field "Access Token", with: "live_12345678"
    assert_checked_field "Production"
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
end
