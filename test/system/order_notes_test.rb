require "application_system_test_case"

class OrderNotesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @order = orders(:one)
    grant_support_access(accounts(:one))
  end

  test "staff can add a note to an order" do
    login_as @admin
    select_account("Account One")
    visit order_url(@order)

    assert_text "NOTES"
    # No longer has "No staff notes yet." text in current UI

    fill_in "Add staff note...", with: "Customer called to say they will be 10 minutes late."
    click_on "Save Note"

    assert_text "Note was successfully created."
    assert_text "Customer called to say they will be 10 minutes late."
    assert_text @admin.name
    assert_no_text "No staff notes yet."
  end

  test "customers cannot see staff notes section" do
    @customer_user = users(:three)

    login_as @customer_user
    # Customer only has one account, so no switcher
    visit order_url(@order)

    assert_no_text "NOTES"
  end
end
