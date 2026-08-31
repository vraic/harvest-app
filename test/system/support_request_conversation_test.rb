require "application_system_test_case"

class SupportRequestConversationTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrator)
    @store_manager = users(:one)
    @account = accounts(:one)
    @support_request = support_requests(:one)
  end

  test "requester and admin can converse on a support request" do
    # 1. Requester adds a comment
    login_as(@store_manager)
    visit support_request_path(@support_request)

    fill_in "Type your message here...", with: "I have some more details."
    click_on "Send Message"

    assert_text "Comment added"
    assert_text "I have some more details."
    assert_text @store_manager.name

    logout

    # 2. Admin replies
    login_as(@admin)
    visit support_request_path(@support_request)

    assert_text "I have some more details."
    fill_in "Type your message here...", with: "Thank you, we are looking into it."
    click_on "Send Message"

    assert_text "Comment added"
    assert_text "Thank you, we are looking into it."
    assert_text "#{@admin.name} (Support Staff)"

    # 3. Admin edits their own comment
    comment = SupportRequestComment.last
    within "##{dom_id comment}" do
      click_on "Edit"
      fill_in "support_request_comment[body]", with: "Actually, we fixed it."
      click_on "Save"
    end

    assert_text "Comment updated"
    assert_text "Actually, we fixed it."
    assert_no_text "Thank you, we are looking into it."
  end
end
