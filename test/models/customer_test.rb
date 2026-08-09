require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    ActsAsTenant.current_tenant = @account
  end

  test "has prefixed id" do
    customer = customers(:one)
    assert_match(/^cust_/, customer.to_param)
    assert_equal customer, Customer.find_by_prefix_id(customer.to_param)
  end

  test "soft deletes customer" do
    customer = customers(:one)
    customer.destroy
    assert_not_nil customer.deleted_at
    assert_nil Customer.find_by(id: customer.id)
    assert_not_nil Customer.with_deleted.find_by(id: customer.id)
  end

  test "really deletes customer" do
    customer = customers(:one)
    customer.destroy_fully!
    assert_nil Customer.with_deleted.find_by(id: customer.id)
  end

  test "anonymises customer fields" do
    customer = customers(:one)
    original_name = customer.name
    original_email = customer.email_address

    assert customer.anonymise!

    assert_not_equal original_name, customer.reload.name
    assert_not_equal original_email, customer.reload.email_address
  end

  test "validates name presence" do
    customer = Customer.new(name: "")
    assert_not customer.valid?
    assert_includes customer.errors[:name], "can't be blank"
  end

  test "retention hold requires non-past keep until date" do
    customer = Customer.new(
      account: @account,
      name: "Retention Customer",
      retention_hold: true,
      retention_hold_until: 1.day.ago.to_date
    )

    assert_not customer.valid?
    assert_includes customer.errors[:retention_hold_until], "must be today or later"
  end

  test "clears retention hold metadata when hold is disabled" do
    customer = customers(:one)

    customer.update!(
      retention_hold: true,
      retention_hold_until: 1.year.from_now.to_date,
      retention_hold_reason: "Minor"
    )

    customer.update!(retention_hold: false)

    customer.reload
    assert_not customer.retention_hold
    assert_nil customer.retention_hold_until
    assert_nil customer.retention_hold_reason
  end

  test "ensuring account user while another tenant is active does not cause RecordNotUnique" do
    user = users(:one)
    account_one = accounts(:one)
    account_two = accounts(:two)

    # Ensure user is already in account_one
    assert AccountUser.unscoped.exists?(account: account_one, user: user)

    ActsAsTenant.with_tenant(account_one) do
      # Create a customer record in account_two for this user
      # We use without_tenant here to simulate a background/system process that
      # can create records across tenants, which is what ensure_account_user might encounter
      customer = Customer.new(account: account_two, user: user, name: "Test Customer")
      ActsAsTenant.without_tenant do
        customer.save!
      end

      assert_equal account_two.id, customer.account_id, "Customer should belong to account_two"

      # Verify AccountUser for account_two was created
      au = AccountUser.unscoped.find_by(account: account_two, user: user)
      assert_not_nil au, "AccountUser should have been created for account_two"
      assert_equal "customer", au.user_role
    end
  end
end
