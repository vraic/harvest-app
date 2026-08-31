require "application_system_test_case"

class NewslettersSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @newsletter = Newsletter.create!(
      account: @account,
      subject: "Draft Newsletter",
      content: "Draft content",
      target: "everyone"
    )
    login_as(@user)
  end

  test "showing and hiding buttons based on sent status" do
    visit newsletters_path

    within "tr", text: "Draft Newsletter" do
      assert_link "Edit"
      assert_button "Delete"
    end

    visit newsletter_path(@newsletter)
    assert_link "Edit"
    assert_button "Deliver Now"

    # Deliver it
    click_on "Deliver Now"

    assert_text "Delivery started"
    assert_no_link "Edit"
    assert_no_button "Deliver Now"

    visit newsletters_path
    within "tr", text: "Draft Newsletter" do
      assert_no_link "Edit"
      assert_no_button "Delete"
    end
  end
end
