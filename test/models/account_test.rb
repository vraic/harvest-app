require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "creating an account while another tenant is active does not cause RecordNotUnique for the owner" do
    user = users(:one)
    other_account = accounts(:one)

    # Ensure user is already in another account (as they are in fixtures)
    assert user.account_users.exists?(account: other_account)

    ActsAsTenant.with_tenant(other_account) do
      new_account = Account.new(name: "New Store", owner: user)
      assert_nothing_raised do
        new_account.save!
      end

      # Verify the user is now also a store_manager of the new account
      assert AccountUser.unscoped.exists?(account: new_account, user: user, user_role: "store_manager")
    end
  end

  test "effective retention values fallback to defaults" do
    account = accounts(:one)

    assert_equal Rails.application.config.x.data_protection.inactive_record_retention_years, account.effective_inactivity_retention_years
    assert_equal Rails.application.config.x.data_protection.soft_delete_retention_days, account.effective_soft_delete_retention_days
    assert_equal Rails.application.config.x.data_protection.inactive_record_retention_action, account.effective_inactive_customer_retention_action
    assert_equal Rails.application.config.x.data_protection.inactive_record_retention_action, account.effective_inactive_supplier_retention_action
  end

  test "effective retention values use store overrides when present" do
    account = accounts(:one)
    account.update!(
      inactivity_retention_years_override: 5,
      soft_delete_retention_days_override: 45,
      inactive_customer_retention_action: "archive",
      inactive_supplier_retention_action: "none"
    )

    assert_equal 5, account.effective_inactivity_retention_years
    assert_equal 45, account.effective_soft_delete_retention_days
    assert_equal "archive", account.effective_inactive_customer_retention_action
    assert_equal "none", account.effective_inactive_supplier_retention_action
  end
end
