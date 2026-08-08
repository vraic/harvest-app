require "test_helper"

class NavigationVisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrator)
    @staff = users(:one)
    @customer = users(:three)
  end

  test "global admin acting on behalf sees staff navigation links" do
    grant_support_access(accounts(:one))
    sign_in_as(@admin)
    # Select an account to ensure acting context uses the staff navigation
    patch managed_account_path, params: { account_id: accounts(:one).id }
    follow_redirect!

    assert_select "body > div.w-full.bg-indigo-600", text: /Admin Support Mode/

    banner_index = response.body.index("Admin Support Mode")
    sidebar_index = response.body.index('id="sidebar"')
    main_index = response.body.index("<main")

    refute_nil banner_index
    refute_nil sidebar_index
    refute_nil main_index
    assert_operator banner_index, :<, sidebar_index
    assert_operator banner_index, :<, main_index

    assert_select "nav" do
      assert_select "a", text: /Dashboard/
      assert_select "a", text: /Tasks/
      assert_select "button", text: /Commerce/
      assert_select "a", text: /Orders/
      assert_select "a", text: /Inventory/
      assert_select "button", text: /People/
      assert_select "a", text: /Customers/
      assert_select "a", text: /Customer View/
      assert_select "div", text: /Quick links/, count: 0
      assert_select "a", text: /Today's Orders/, count: 0
      assert_select "a", text: /Recent Customers/, count: 0
      assert_select "a", text: /Administration/, count: 0
      assert_select "a", text: /Support Requests/, count: 0
    end
  end

  test "global admin without active support authorization does not see staff quick links" do
    ActsAsTenant.without_tenant do
      SupportRequest.delete_all
      AccountUser.unscoped.find_or_create_by!(user: @admin, account: accounts(:one)) do |account_user|
        account_user.user_role = :store_manager
      end
    end

    sign_in_as(@admin)
    get dashboard_path
    assert_response :success

    assert_select "nav" do
      assert_select "a", text: /Administration/
      assert_select "a", text: /Support Requests/
      assert_select "div", text: /Quick links/, count: 0
      assert_select "a", text: /Today's Orders/, count: 0
      assert_select "a", text: /Recent Customers/, count: 0
      assert_select "a", text: /Tasks/, count: 0
      assert_select "a", text: /Customers/, count: 0
    end
  end

  test "staff user sees all links" do
    sign_in_as(@staff)
    get dashboard_path
    assert_select "nav" do
      assert_select "a", text: /Tasks/
      assert_select "button", text: /Commerce/
      assert_select "button", text: /People/
      assert_select "a", text: /Customers/
      assert_select "a", text: /Inventory/
      assert_select "a", text: /Orders/
      assert_select "a", text: /Store Settings/
      assert_select "div", text: /Quick links/, count: 0
    end
  end

  test "customer user sees only limited links" do
    sign_in_as(@customer)
    get dashboard_path
    assert_response :success

    assert_select "nav" do
      assert_select "a", text: /Dashboard/
      assert_select "a", text: /Orders/
      assert_select "a", text: /Tasks/, count: 0
      assert_select "a", text: /Customers/, count: 0
      assert_select "a", text: /Inventory/, count: 0
      assert_select "a", text: /Reports/, count: 0
      assert_select "a", text: /Settings/, count: 0
    end
  end
end
