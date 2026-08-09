require "test_helper"

class PurgeDeletedRecordsJobTest < ActiveJob::TestCase
  test "purges only soft-deleted records older than retention window" do
    account_one = accounts(:one)
    user_old = User.create!(
      email_address: "purge-old@example.com",
      password: "ComplexPassword123!",
      password_confirmation: "ComplexPassword123!",
      name: "Purge User Old",
      onboarded: true
    )
    user_recent = User.create!(
      email_address: "purge-recent@example.com",
      password: "ComplexPassword123!",
      password_confirmation: "ComplexPassword123!",
      name: "Purge User Recent",
      onboarded: true
    )

    customer_old = ActsAsTenant.with_tenant(account_one) do
      Customer.create!(account: account_one, name: "Purge Customer Old", email_address: "purge-customer-old@example.com")
    end

    supplier_old = ActsAsTenant.with_tenant(account_one) do
      Supplier.create!(account: account_one, name: "Purge Supplier Old", email_address: "purge-supplier-old@example.com")
    end

    ActsAsTenant.with_tenant(account_one) do
      user_old.destroy!
      customer_old.destroy!
      supplier_old.destroy!
    end

    user_recent.destroy!

    User.unscoped.where(id: user_old.id).update_all(deleted_at: 120.days.ago)
    User.unscoped.where(id: user_recent.id).update_all(deleted_at: 5.days.ago)
    Customer.unscoped.where(id: customer_old.id).update_all(deleted_at: 120.days.ago)
    Supplier.unscoped.where(id: supplier_old.id).update_all(deleted_at: 120.days.ago)

    PurgeDeletedRecordsJob.perform_now(retention_days: 90)

    assert_nil User.with_deleted.find_by(id: user_old.id)
    assert User.with_deleted.find_by(id: user_recent.id).present?
    assert_nil Customer.with_deleted.find_by(id: customer_old.id)
    assert_nil Supplier.with_deleted.find_by(id: supplier_old.id)
  end
end
