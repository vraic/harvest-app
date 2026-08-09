require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrator = users(:administrator)
    @account = accounts(:one)

    sign_in_as(@administrator)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should get new" do
    get new_account_url
    assert_response :success
  end

  test "should create account" do
    assert_difference("Account.count") do
      post accounts_url, params: { account: { address: @account.address, name: @account.name, owner_id: @administrator.id } }
    end

    assert_redirected_to account_url(Account.last)
  end

  test "should show account" do
    get account_url(@account)
    assert_response :success
  end

  test "should get edit" do
    get edit_account_url(@account)
    assert_response :success
  end

  test "should update account" do
    patch account_url(@account), params: {
      account: {
        address: @account.address,
        name: @account.name,
        owner_id: @account.owner_id,
        inactivity_retention_years_override: 6,
        soft_delete_retention_days_override: 120,
        inactive_customer_retention_action: "archive",
        inactive_supplier_retention_action: "none"
      }
    }

    @account.reload

    assert_equal 6, @account.inactivity_retention_years_override
    assert_equal 120, @account.soft_delete_retention_days_override
    assert_equal "archive", @account.inactive_customer_retention_action
    assert_equal "none", @account.inactive_supplier_retention_action
    assert_redirected_to account_url(@account)
  end

  test "should destroy account" do
    account = Account.create!(name: "To Destroy", owner_id: @administrator.id)
    assert_difference("Account.count", -1) do
      delete account_url(account)
    end

    assert_redirected_to accounts_url
  end
end
