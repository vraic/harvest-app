require "application_system_test_case"

class RecentCustomersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    login_as @user
  end

  test "can view recent customers" do
    # Create a recent customer
    Customer.create!(name: "Recent Customer", email_address: "recent@example.com", account: accounts(:one), created_at: 1.day.ago)
    # Create an old customer
    Customer.create!(name: "Old Customer", email_address: "old@example.com", account: accounts(:one), created_at: 10.days.ago)

    visit customers_path(filter: "recent")

    assert_text "Recent Customer"
    assert_no_text "Old Customer"
  end
end
