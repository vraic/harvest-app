require "application_system_test_case"

class DashboardMembershipsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Joiner", email_address: "joiner@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong", onboarded: true, security_choice_made: true)
    # Ensure there's a store to join
    @store_to_join = accounts(:two)
  end

  test "joining a store updates the dashboard" do
    login_as @user

    visit dashboard_path

    # Check if Account Two is available to join
    within "#stores-grid" do
      assert_text @store_to_join.name
      card = find("h3", text: @store_to_join.name).find(:xpath, "ancestor::div[contains(@class, 'flex-col')]")
      within card do
        click_on "Visit Shop"
      end
    end

    assert_text "Joined #{@store_to_join.name}"

    # Now check dashboard again (should be redirected there)
    assert_current_path dashboard_path

    # Account Two should now be in the stores grid with customer label
    within "#stores-grid" do
      assert_text @store_to_join.name
      assert_text "customer"
    end
  end
end
