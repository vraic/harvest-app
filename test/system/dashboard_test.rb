require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Store Searcher", email_address: "searcher@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong", onboarded: true, security_choice_made: true)
    @account = accounts(:two) # An account the user is not part of yet
  end

  test "available stores are shown in a grid" do
    login_as(@user)

    visit dashboard_path

    assert_text "Stores"
    within "#stores-grid" do
      assert_text @account.name
      # Verify the specific card exists
      assert_selector "h3", text: @account.name
    end
  end

  test "can visit shop from dashboard grid" do
    login_as(@user)

    visit dashboard_path

    # Find the specific card for the account
    card = find("h3", text: @account.name).find(:xpath, "ancestor::div[contains(@class, 'flex-col')]")
    within card do
      click_button "Visit Shop"
    end

    assert_text "Joined #{@account.name}"
    assert_text "Active" # Should show as active now
    assert_text "customer" # Should show the customer label
  end
end
