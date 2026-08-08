require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  setup do
    resize_to_desktop
    @manager = User.create!(name: "Store Manager", email_address: "manager@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")
    @staff = User.create!(name: "Store Staff", email_address: "staff@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")

    @account = Account.create!(name: "Managed Store", owner: @manager)
    AccountUser.create!(account: @account, user: @staff, user_role: :store_staff)
  end

  test "manager sees Store Settings in sidebar" do
    login_as(@manager)
    visit dashboard_path

    # Check desktop sidebar
    within "#desktop-sidebar-main-nav" do
      assert_text "Store Settings"
      click_on "Store Settings"
    end

    assert_current_path edit_account_path(@account)
    assert_text "Editing account"
    assert_text "Stores We Supply"
  end

  test "manager sees Store Settings in mobile sidebar" do
    resize_to_mobile
    login_as(@manager)
    visit dashboard_path

    find("button", text: "Open sidebar").click

    within "#mobile-sidebar-main-nav" do
      assert_text "Store Settings"
      click_on "Store Settings"
    end

    assert_current_path edit_account_path(@account)
  end

  test "manager with multiple stores can switch and see correct settings" do
    @account2 = Account.create!(name: "Second Store", owner: @manager)

    login_as(@manager)
    visit dashboard_path

    click_on "Switch Account"
    within "#account-switcher" do
      row = find("li", text: "Second Store")
      within row do
        click_on "Switch"
      end
    end

    assert_text "Switched to Second Store"

    within "#desktop-sidebar-main-nav" do
      assert_text "Store Settings"
      click_on "Store Settings"
    end

    assert_current_path edit_account_path(@account2)
    assert_text "Editing account"
    assert_field "Name", with: "Second Store"
    assert_text "Stores We Supply"
  end

  test "staff does not see Store Settings in sidebar" do
    login_as(@staff)
    visit dashboard_path

    within "#desktop-sidebar-main-nav" do
      assert_no_text "Store Settings"
    end
  end
end
