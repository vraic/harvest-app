require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home renders marketing page for unauthenticated visitors" do
    get root_path

    assert_response :success
    assert_select "h1", "Harvest exists to inspire new ways of thinking and being, so that everyone can live life to the fullest."
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

  test "terms renders for unauthenticated visitors" do
    get terms_path

    assert_response :success
    assert_select "h1", "Terms of Service"
  end

  test "terms renders for authenticated users" do
    sign_in_as(users(:one))

    get terms_path

    assert_response :success
    assert_select "h1", "Terms of Service"
  end

  test "privacy renders for unauthenticated visitors" do
    get privacy_path

    assert_response :success
    assert_select "h1", "Privacy Policy"
  end

  test "privacy renders for authenticated users" do
    sign_in_as(users(:one))

    get privacy_path

    assert_response :success
    assert_select "h1", "Privacy Policy"
  end

  test "terms links to privacy policy" do
    get terms_path

    assert_response :success
    assert_select "a[href=?]", privacy_path, text: "Privacy Policy"
  end
end
