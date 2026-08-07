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

    within "nav" do
      assert_text "Dashboard"
      assert_text "Newsletters"
      assert_text "Loyalty"

      # Newsletters link for staff points to newsletters_path
      assert_selector "a[href='/newsletters']"
      refute_selector "a[href='/customer/newsletters']"

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

  test "customer sees global shop and customer-facing links" do
    login_as(@customer)

    # No longer redirected to shop automatically
    visit dashboard_path
    assert_current_path dashboard_path

    within "nav" do
      assert_text "Dashboard"
      assert_text "Newsletters"
      assert_text "Loyalty"

      # Should see customer versions
      assert_selector "a[href='/customer/newsletters']"
      assert_selector "a[href='/customer/loyalty_programs']"

      # Should NOT see staff versions
      refute_selector "a[href='/newsletters']"
      refute_selector "a[href='/loyalty_cards']"
    end
  end

  test "admin sees management links but not customer-facing ones" do
    login_as(users(:administrator))

    visit root_path

    within "nav" do
      assert_text "Dashboard"
      assert_text "Newsletters"
      assert_text "Loyalty"

      assert_selector "a[href='/newsletters']"
      refute_selector "a[href='/customer/newsletters']"

      assert_selector "a[href='/loyalty_cards']"
      refute_selector "a[href='/customer/loyalty_programs']"
    end
  end
end
