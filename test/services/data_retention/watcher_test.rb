require "test_helper"

module DataRetention
  class WatcherTest < ActiveSupport::TestCase
    test "archives inactive customers based on last order activity" do
      account = accounts(:one)
      location = locations(:one)
      account.update!(
        inactivity_retention_years_override: 7,
        inactive_customer_retention_action: "archive",
        inactive_supplier_retention_action: "none"
      )

      stale_customer = nil
      recent_customer = nil

      travel_to Time.zone.local(2026, 8, 1, 12, 0, 0) do
        stale_customer = ActsAsTenant.with_tenant(account) do
          Customer.create!(account: account, name: "Stale Customer", email_address: "stale-retention@example.com", updated_at: 10.years.ago)
        end

        recent_customer = ActsAsTenant.with_tenant(account) do
          customer = Customer.create!(account: account, name: "Recent Customer", email_address: "recent-retention@example.com", updated_at: 10.years.ago)
          Order.create!(
            account: account,
            customer: customer,
            location: location,
            number: "RET111",
            status: :ordered,
            total_amount_cents: 1000,
            currency: "GBP",
            created_at: 1.year.ago,
            updated_at: 1.year.ago
          )
          customer
        end

        ActsAsTenant.with_tenant(account) do
          DataRetention::Watcher.new(account: account, now: Time.current).run
        end
      end

      assert Customer.with_deleted.find_by(id: stale_customer.id).deleted?
      assert_not Customer.with_deleted.find_by(id: recent_customer.id).deleted?
      assert DataRetentionEvent.exists?(
        account: account,
        record_type: "Customer",
        record_id: stale_customer.id,
        event_type: "automated_archive"
      )
    end

    test "anonymises and archives inactive suppliers" do
      account = accounts(:one)
      account.update!(
        inactivity_retention_years_override: 7,
        inactive_customer_retention_action: "none",
        inactive_supplier_retention_action: "anonymise"
      )

      stale_supplier = nil

      travel_to Time.zone.local(2026, 8, 1, 12, 0, 0) do
        stale_supplier = ActsAsTenant.with_tenant(account) do
          Supplier.create!(account: account, name: "Supplier Retention", email_address: "supplier-retention@example.com", updated_at: 10.years.ago)
        end

        original_name = stale_supplier.name
        original_email = stale_supplier.email_address

        ActsAsTenant.with_tenant(account) do
          DataRetention::Watcher.new(account: account, now: Time.current).run
        end

        archived_supplier = Supplier.with_deleted.find(stale_supplier.id)
        assert archived_supplier.deleted?
        assert_not_equal original_name, archived_supplier.name
        assert_not_equal original_email, archived_supplier.email_address
        assert DataRetentionEvent.exists?(
          account: account,
          record_type: "Supplier",
          record_id: stale_supplier.id,
          event_type: "automated_anonymise_archive"
        )
      end
    end

    test "skips held records and logs hold event" do
      account = accounts(:one)
      account.update!(
        inactivity_retention_years_override: 7,
        inactive_customer_retention_action: "archive",
        inactive_supplier_retention_action: "none"
      )

      held_customer = nil

      travel_to Time.zone.local(2026, 8, 1, 12, 0, 0) do
        held_customer = ActsAsTenant.with_tenant(account) do
          Customer.create!(
            account: account,
            name: "Held Customer",
            email_address: "held-retention@example.com",
            updated_at: 10.years.ago,
            retention_hold: true,
            retention_hold_until: 2.years.from_now.to_date,
            retention_hold_reason: "Minor"
          )
        end

        ActsAsTenant.with_tenant(account) do
          DataRetention::Watcher.new(account: account, now: Time.current).run
        end
      end

      assert_not Customer.with_deleted.find(held_customer.id).deleted?
      assert DataRetentionEvent.exists?(
        account: account,
        record_type: "Customer",
        record_id: held_customer.id,
        event_type: "held_record_skipped"
      )
    end
  end
end
