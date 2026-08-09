require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "can update personal information" do
    login_as @user
    visit settings_path

    fill_in "Name", with: "Jane Smith"
    fill_in "Email address", with: "jane@example.com"

    click_on "Save", match: :first

    assert_text "Personal information updated"
    @user.reload
    assert_equal "Jane Smith", @user.name
    assert_equal "jane@example.com", @user.email_address
  end

  test "can update password" do
    login_as @user
    visit settings_path

    within "form[action='#{update_password_settings_path}']" do
      fill_in "Current password", with: "password"
      fill_in "New password", with: "ComplexPassword123!"
      fill_in "Confirm password", with: "ComplexPassword123!"
      click_on "Save"
    end

    assert_text "Password updated successfully"
    assert @user.reload.authenticate("ComplexPassword123!")
  end

  test "can logout other sessions" do
    login_as @user
    @user.sessions.create!(ip_address: "1.2.3.4", user_agent: "Other Browser")
    assert_equal 2, @user.sessions.count # One current (from login_as), one other

    visit settings_path

    fill_in "Your password", with: "password"
    click_on "Log out other sessions"

    assert_text "Other sessions logged out"
    assert_equal 1, @user.sessions.count
  end

  test "can archive account" do
    login_as @user
    visit settings_path
    assert_text "archive your account"
    before_count = DataSubjectRequest.uncached { DataSubjectRequest.count }

    accept_confirm do
      click_on "Yes, archive my account"
    end

    assert_text "Account archived"
    assert_equal before_count + 1, DataSubjectRequest.uncached { DataSubjectRequest.count }

    request = DataSubjectRequest.order(:id).last
    assert request.completed?
    assert request.erasure?
    assert request.offboarding_archive?
    assert_nil User.find_by(id: @user.id)
  end
end
