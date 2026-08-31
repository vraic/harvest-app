require "application_system_test_case"

class GlobalAdminSupportTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)

    @store_manager = users(:two)
    # Ensure user two ONLY belongs to account one for this test
    AccountUser.unscoped.where(user: @store_manager).delete_all
    @account = accounts(:one)
    AccountUser.unscoped.create!(user: @store_manager, account: @account, user_role: :store_manager)

    # Ensure inventory item for the test
    @item = inventory_items(:one)
    @item.update!(account: @account)
  end

  test "full support workflow" do
    # 1. Store manager requests support
    login_as(@store_manager)
    visit support_requests_path
    click_on "New Support Request"
    fill_in "How can we help?", with: "We need help with inventory management."
    click_on "Submit Request"
    assert_text "Request created"
    assert_text "Pending"

    # Logout
    logout

    # 2. Global admin manages the request
    login_as(@admin)
    visit support_requests_path
    assert_text "We need help with inventory management."

    # Scope to the specific request
    support_request = SupportRequest.last
    within "##{dom_id support_request}" do
      click_on "Accept"
    end
    assert_text "Request accepted"
    assert_text "Expires:"

    # 3. Global admin joins the account
    within "##{dom_id support_request}" do
      click_on "Join Account"
    end
    assert_text "Joined support session"
    assert_text "Acting on behalf of: Account One"

    # 4. Global admin performs an audited action in the account
    visit inventory_items_path
    # Assuming there's an item in the account
    item = inventory_items(:one)
    visit inventory_item_path(item)
    click_on "Edit"
    fill_in "Name", with: "Updated Item Name"
    click_on "Update Inventory item"
    assert_text "Item updated"

    # 5. Verify audit exists
    visit audits_account_path(@account)
    assert_text "Updated Item Name"
    assert_text @admin.name

    # 6. Global admin leaves the account
    click_on "Leave Account"
    assert_text "Left support session"
    assert_no_text "Acting on behalf of: Account One"
  end

  test "admin initiated support request" do
    # 1. Admin initiates request
    login_as(@admin)
    visit support_requests_path
    click_on "New Support Request"
    select "Account One", from: "Select Account"
    fill_in "How can we help?", with: "Admin needs access for maintenance."
    click_on "Submit Request"
    assert_text "Request created"

    logout

    # 2. Store manager accepts
    login_as(@store_manager)
    # select_account not needed as they belong to one
    visit support_requests_path
    assert_text "Admin needs access for maintenance."
    click_on "Accept"
    assert_text "Request accepted"

    logout

    # 3. Admin can now join
    login_as(@admin)
    visit support_requests_path

    # Scope to the specific request
    support_request = SupportRequest.last
    within "##{dom_id support_request}" do
      click_on "Join Account"
    end
    assert_text "Acting on behalf of: Account One"
  end

  test "extension request workflow" do
    # Create an active request
    request = SupportRequest.create!(
      account: @account,
      requester: @store_manager,
      status: :accepted,
      expires_at: 1.hour.from_now,
      message: "Short request"
    )

    login_as(@admin)
    visit support_requests_path
    assert_text "Short request"

    # Request extension
    within "##{dom_id request}" do
      click_on "Request Extension"
    end
    assert_text "Extension requested"

    logout

    # Store manager grants extension
    login_as(@store_manager)
    visit support_requests_path

    # Force reveal hidden elements
    page.execute_script("document.querySelectorAll('.hidden').forEach(el => el.classList.remove('hidden'))")
    click_on "+72h"
    assert_text "Authorization extended"
  end
end
