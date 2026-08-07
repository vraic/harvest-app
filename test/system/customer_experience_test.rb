require "application_system_test_case"

class CustomerExperienceTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    login_as(@user)

    # Ensure they are only a customer for testing dashboard removal
    ActsAsTenant.without_tenant do
      @user.account_users.update_all(user_role: :customer)
    end
  end

  test "customer sees dashboard and can navigate to shop" do
    visit dashboard_path
    assert_current_path dashboard_path

    # On desktop nav
    within "#desktop-sidebar-main-nav" do
      assert_text "Dashboard"
      assert_text "Shop"
      assert_text "Newsletters"
      assert_text "Loyalty"
    end
  end

  test "customer can access newsletters" do
    visit shop_path

    within "#desktop-sidebar-main-nav" do
      click_on "Newsletters"
    end

    assert_text "Your Newsletters"
    assert_text "Recent Archives"
  end

  test "customer can manage loyalty programs" do
    visit shop_path

    within "#desktop-sidebar-main-nav" do
      click_on "Loyalty"
    end

    assert_text "Loyalty Programmes"

    # Account One has an active loyalty program in fixtures
    # We use match: :first because there might be multiple buttons if multiple programs exist
    click_on "Enrol Now", match: :first

    assert_text "You have successfully enrolled"
    assert_text "Account One Loyalty"
    assert_text "Current Balance"
    assert_text "Recent Activity"

    # Go back to index
    click_on "Back to All Programmes"
    assert_text "Enrolled"
  end
end
