require "test_helper"

class Madmin::AccessControlTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login" do
    get madmin_root_path

    assert_redirected_to new_session_path
  end

  test "non-admin user is denied access" do
    sign_in_as(users(:two))

    get madmin_root_path

    assert_redirected_to root_path
    assert_equal I18n.t("unauthorized"), flash[:alert]
  end

  test "admin user can access madmin" do
    sign_in_as(users(:administrator))

    get madmin_root_path

    assert_response :success
  end
end
