require "application_system_test_case"

class SidebarUserMenuTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Test User", email_address: "test@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")
    @account = Account.create!(name: "Test Store", owner: @user)

    @staff_user = User.create!(name: "Staff User", email_address: "staff@example.com", password: "Password123!@#Strong", password_confirmation: "Password123!@#Strong")
    AccountUser.create!(account: @account, user: @staff_user, user_role: :store_staff)
  end

  test "manager sees name, role and can open menu on desktop" do
    resize_to_desktop
    login_as(@user)
    visit dashboard_path

    within "#user-menu-button-desktop" do
      assert_text "Test User"
      assert_text "Store Manager"
    end

    # Menu should be hidden initially
    assert_selector "[data-dropdown-target='menu']", visible: false

    # Click to open
    click_on "user-menu-button-desktop"

    assert_selector "[data-dropdown-target='menu']", visible: true
    within "[data-dropdown-target='menu']" do
      assert_link "Guides"
      assert_link "Settings"
      assert_link "Support"
      assert_button "Logout"

      menu_entries = all("a", visible: :all).map { |link| link.text.strip }
      assert_operator menu_entries.index("Guides"), :<, menu_entries.index("Settings")
    end

    # Test hiding by clicking outside (simulated by clicking elsewhere)
    find("main").click
    assert_selector "[data-dropdown-target='menu']", visible: false
  end

  test "staff sees correct role and cannot see store settings" do
    resize_to_desktop
    login_as(@staff_user)
    visit dashboard_path

    within "#user-menu-button-desktop" do
      assert_text "Staff User"
      assert_text "Store Staff"
    end

    within "nav" do
      assert_no_text "Store Settings"
    end
  end

  test "manager sees store settings" do
    resize_to_desktop
    login_as(@user)
    visit dashboard_path

    within "nav" do
      assert_text "Store Settings"
    end
  end

  test "mobile sidebar also has user menu" do
    resize_to_mobile
    login_as(@user)
    visit dashboard_path

    find("button", text: "Open sidebar").click

    within "#user-menu-button-mobile" do
      assert_text "Test User"
      assert_text "Store Manager"
    end

    click_on "user-menu-button-mobile"

    within "#sidebar" do # Mobile sidebar is in a dialog
      assert_link "Guides"
      assert_link "Settings"
      assert_link "Support"
      assert_button "Logout"

      menu_entries = all("[data-dropdown-target='menu'] a", visible: :all).map { |link| link.text.strip }
      assert_operator menu_entries.index("Guides"), :<, menu_entries.index("Settings")
    end
  end
end
