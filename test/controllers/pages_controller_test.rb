require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home renders marketing page for unauthenticated visitors" do
    get root_path

    assert_response :success
    assert_select "h1", "Harvest exists to inspire new ways of thinking and being, so that everyone can live life to the fullest."
    assert_select "nav[aria-label='Homepage'] a[href='#invitation']", text: "An invitation"
    assert_select "nav[aria-label='Homepage'] a[href='#look']", text: "Look inside"
    assert_select "nav[aria-label='Homepage'] a[href='#questions']", text: "Hard questions"
    assert_select "a[href=?]", new_session_path, text: "Login", minimum: 1
    assert_select "a[href=?]", new_session_path, text: "Get started"
  end

  test "home redirects signed-in staff users to dashboard" do
    sign_in_as(users(:one))

    get root_path

    assert_redirected_to dashboard_path
  end

  test "home redirects signed-in customer users to shop" do
    sign_in_as(users(:three))

    get root_path

    assert_redirected_to shop_path
  end

  test "home redirects signed-in admin users to dashboard" do
    sign_in_as(users(:administrator))

    get root_path

    assert_redirected_to dashboard_path
  end
end
