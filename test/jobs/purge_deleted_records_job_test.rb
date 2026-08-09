require "test_helper"

class PurgeDeletedRecordsJobTest < ActiveJob::TestCase
  test "purges soft-deleted records using store retention overrides and global user retention" do
    account_one = accounts(:one)
    account_two = accounts(:two)

    account_one.update!(soft_delete_retention_days_override: 120)
    account_two.update!(soft_delete_retention_days_override: 30)

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

    customer_old_account_one = ActsAsTenant.with_tenant(account_one) do
      Customer.create!(account: account_one, name: "Purge Customer Old", email_address: "purge-customer-old@example.com")
    end

    customer_old_account_two = ActsAsTenant.with_tenant(account_two) do
      Customer.create!(account: account_two, name: "Purge Customer Old Two", email_address: "purge-customer-old-two@example.com")
    end

    customer_held_account_two = ActsAsTenant.with_tenant(account_two) do
      Customer.create!(
        account: account_two,
        name: "Purge Customer Held Two",
        email_address: "purge-customer-held-two@example.com",
        retention_hold: true,
        retention_hold_until: 1.year.from_now.to_date,
        retention_hold_reason: "Minor"
      )
    end

    supplier_old_account_one = ActsAsTenant.with_tenant(account_one) do
      Supplier.create!(account: account_one, name: "Purge Supplier Old", email_address: "purge-supplier-old@example.com")
    end

    supplier_old_account_two = ActsAsTenant.with_tenant(account_two) do
      Supplier.create!(account: account_two, name: "Purge Supplier Old Two", email_address: "purge-supplier-old-two@example.com")
    end

    supplier_held_account_two = ActsAsTenant.with_tenant(account_two) do
      Supplier.create!(
        account: account_two,
        name: "Purge Supplier Held Two",
        email_address: "purge-supplier-held-two@example.com",
        retention_hold: true,
        retention_hold_until: 1.year.from_now.to_date,
        retention_hold_reason: "Legal hold"
      )
    end

    ActsAsTenant.with_tenant(account_one) do
      user_old.destroy!
      customer_old_account_one.destroy!
      supplier_old_account_one.destroy!
    end

    ActsAsTenant.with_tenant(account_two) do
      customer_old_account_two.destroy!
      customer_held_account_two.destroy!
      supplier_old_account_two.destroy!
      supplier_held_account_two.destroy!
    end

    user_recent.destroy!

    User.unscoped.where(id: user_old.id).update_all(deleted_at: 120.days.ago)
    User.unscoped.where(id: user_recent.id).update_all(deleted_at: 5.days.ago)
    Customer.unscoped.where(id: customer_old_account_one.id).update_all(deleted_at: 100.days.ago)
    Customer.unscoped.where(id: customer_old_account_two.id).update_all(deleted_at: 100.days.ago)
    Customer.unscoped.where(id: customer_held_account_two.id).update_all(deleted_at: 100.days.ago)
    Supplier.unscoped.where(id: supplier_old_account_one.id).update_all(deleted_at: 100.days.ago)
    Supplier.unscoped.where(id: supplier_old_account_two.id).update_all(deleted_at: 100.days.ago)
    Supplier.unscoped.where(id: supplier_held_account_two.id).update_all(deleted_at: 100.days.ago)

    PurgeDeletedRecordsJob.perform_now(retention_days: 90)

    assert_nil User.with_deleted.find_by(id: user_old.id)
    assert User.with_deleted.find_by(id: user_recent.id).present?
    assert Customer.with_deleted.find_by(id: customer_old_account_one.id).present?
    assert_nil Customer.with_deleted.find_by(id: customer_old_account_two.id)
    assert Customer.with_deleted.find_by(id: customer_held_account_two.id).present?
    assert Supplier.with_deleted.find_by(id: supplier_old_account_one.id).present?
    assert_nil Supplier.with_deleted.find_by(id: supplier_old_account_two.id)
    assert Supplier.with_deleted.find_by(id: supplier_held_account_two.id).present?

    assert DataRetentionEvent.exists?(account: account_two, record_type: "Customer", record_id: customer_old_account_two.id, event_type: "automated_purge")
    assert DataRetentionEvent.exists?(account: account_two, record_type: "Supplier", record_id: supplier_old_account_two.id, event_type: "automated_purge")
    assert DataRetentionEvent.exists?(account: account_two, record_type: "Customer", record_id: customer_held_account_two.id, event_type: "held_record_skipped")
    assert DataRetentionEvent.exists?(account: account_two, record_type: "Supplier", record_id: supplier_held_account_two.id, event_type: "held_record_skipped")
  end
end
