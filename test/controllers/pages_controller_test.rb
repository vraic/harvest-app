require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home renders marketing page for unauthenticated visitors" do
    get root_path

    assert_response :success
    assert_select "h1", "One place to run daily farm operations."
    assert_select "nav[aria-label='Homepage'] a[href='#features']", text: "Features"
    assert_select "nav[aria-label='Homepage'] a[href='#platform']", text: "Platform"
    assert_select "nav[aria-label='Homepage'] a[href='#overview']", text: "Overview"
    assert_select "nav[aria-label='Homepage'] a[href='#faq']", text: "Use cases"
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
