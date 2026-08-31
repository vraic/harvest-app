require "application_system_test_case"

class AdminManagedMembershipTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @managed_account = accounts(:one)
    @store_two = accounts(:two)
    @store_three = accounts(:three)
    grant_support_access(@managed_account)
  end

  test "global admin managing an account can join multiple stores for that account" do
    login_as @admin

    # Start managing Account One by Joining it
    select_account("Account One")

    # Join Account Two
    within "#stores-grid" do
      card = find("h3", text: "Account Two").find(:xpath, "ancestor::div[contains(@class, 'flex-col')]")
      within card do
        click_on "Visit Shop"
      end
    end

    assert_text "Joined Account Two"

    # Verify we are still managing Account One and see Account Two joined
    within "#stores-grid" do
      assert_text "Account Two"
      assert_text "business membership"
    end

    # Join Account Three
    within "#stores-grid" do
      card = find("h3", text: "Account Three").find(:xpath, "ancestor::div[contains(@class, 'flex-col')]")
      within card do
        click_on "Visit Shop"
      end
    end

    assert_text "Joined Account Three"

    # Verify we are still managing Account One and see both stores joined
    within "#stores-grid" do
      assert_text "Account Two"
      assert_text "business membership"
      assert_text "Account Three"
      assert_text "business membership"
    end

    # Verify joined stores are NOT in the "Join a Store" list anymore
    # In fact, since no stores are left to join, the section should be gone
    assert_no_text "Join a Store"
  end
end
