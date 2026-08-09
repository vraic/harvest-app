require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  test "visiting new sessions page" do
    visit new_session_url

    assert_selector "h1", text: "Sign in to Harvest"
  end
end
