require "application_system_test_case"

class StaffNavigationTest < ApplicationSystemTestCase
  setup do
    @staff = users(:one)
    @account = accounts(:one)
    @customer = users(:three)
  end

  test "staff member sees management links but not customer-facing ones" do
    login_as(@staff)

    # Select account
    visit root_path
    assert_equal "Dashboard", find("#desktop-sidebar-main-nav > ul > li:first-child > ul > li:first-child a").text

    within "nav" do
      assert_text "Dashboard"
      assert_text "Customer View"
      assert_text "Newsletters"
      assert_text "Loyalty"
      assert_no_text "Notifications"

      assert_selector "a[aria-label='Notifications'][href='/notifications']"
      assert_no_selector "#desktop-notifications-badge"

      # Newsletters link for staff points to newsletters_path
      assert_selector "a[href='/newsletters']"
      refute_selector "a[href='/customer/newsletters']"

      # Shop is available as customer view in staff flow
      assert_selector "a[href='/shop']", text: "Customer View"

      # Loyalty link for staff points to loyalty_cards_path
      assert_selector "a[href='/loyalty_cards']"
      refute_selector "a[href='/customer/loyalty_programs']"
    end

    # Visit Loyalty Cards as staff
    click_on "Loyalty"
    assert_text "Loyalty Cards"
    assert_text @account.name
    assert_text "Total Enrolled"
  end

  test "staff member sees unread notifications bubble" do
    TaskAssignedNotifier.with(record: tasks(:one), account_id: @account.id).deliver(@staff)

    login_as(@staff)
    visit dashboard_path

    within "#desktop-sidebar-main-nav" do
      assert_selector "a[aria-label='Notifications'][href='/notifications']"
      assert_selector "#desktop-notifications-badge", text: "1"
    end
  end

  test "staff member sees supplier view when b2c is off and b2b is on" do
    original_b2c = @account.is_b2c
    original_b2b = @account.is_b2b
    @account.update!(is_b2c: false, is_b2b: true)

    login_as(@staff)
    visit dashboard_path

    within "nav" do
      assert_text "Supplier View"
      assert_no_text "Customer View"
      assert_selector "a[href='/shop']", text: "Supplier View"
    end
  ensure
    @account.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end

  test "staff member does not see shop link when b2c and b2b are both off" do
    original_b2c = @account.is_b2c
    original_b2b = @account.is_b2b
    @account.update!(is_b2c: false, is_b2b: false)

    login_as(@staff)
    visit dashboard_path

    within "nav" do
      assert_no_text "Customer View"
      assert_no_text "Supplier View"
      refute_selector "a[href='/shop']"
    end
  ensure
    @account.update!(is_b2c: original_b2c, is_b2b: original_b2b)
  end

  test "customer sees global shop and customer-facing links" do
    login_as(@customer)

    # No longer redirected to shop automatically
    visit dashboard_path
    assert_current_path dashboard_path
    assert_equal "Dashboard", find("#desktop-sidebar-main-nav > ul > li:first-child > ul > li:first-child a").text

    within "nav" do
      assert_text "Dashboard"
      assert_text "Shop"
      assert_text "Newsletters"
      assert_text "Loyalty"
      assert_no_text "Customer View"

      # Should see customer versions
      assert_selector "a[href='/customer/newsletters']"
      assert_selector "a[href='/customer/loyalty_programs']"

      # Should NOT see staff versions
      refute_selector "a[href='/newsletters']"
      refute_selector "a[href='/loyalty_cards']"
    end
  end

  test "admin sees admin-scoped links in global view" do
    login_as(users(:administrator))

    visit root_path

    within "nav" do
      assert_text "Dashboard"
      assert_text "Administration"
      assert_text "Support Requests"

      assert_selector "a[href='/accounts']"
      assert_selector "a[href='/support_requests']"

      refute_selector "a[href='/tasks']"
      refute_selector "a[href='/newsletters']"
      refute_selector "a[href='/customer/newsletters']"
      refute_selector "a[href='/loyalty_cards']"
    end
  end
end
