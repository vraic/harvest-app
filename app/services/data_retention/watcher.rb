module DataRetention
  class Watcher
    attr_reader :account, :policy, :now

    def initialize(account:, policy: DataRetention::Policy.new(account), now: Time.current)
      @account = account
      @policy = policy
      @now = now
    end

    def run
      process_customers
      process_suppliers
    end

    private

    def process_customers
      action = policy.inactive_customer_action
      return if action == "none"

      cutoff = policy.inactivity_cutoff_time(reference_time: now)
      account.customers.find_each do |customer|
        next unless inactive_customer?(customer, cutoff)
        if held_for_retention?(customer)
          record_held_event(customer, action)
          next
        end

        apply_action(customer, action)
      rescue ActiveRecord::InvalidForeignKey => e
        Rails.logger.warn("Skipping retention action for Customer##{customer.id}: #{e.message}")
      end
    end

    def process_suppliers
      action = policy.inactive_supplier_action
      return if action == "none"

      cutoff = policy.inactivity_cutoff_time(reference_time: now)
      account.suppliers.find_each do |supplier|
        next unless supplier.updated_at < cutoff
        if held_for_retention?(supplier)
          record_held_event(supplier, action)
          next
        end

        apply_action(supplier, action)
      rescue ActiveRecord::InvalidForeignKey => e
        Rails.logger.warn("Skipping retention action for Supplier##{supplier.id}: #{e.message}")
      end
    end

    def inactive_customer?(customer, cutoff)
      last_order_at = customer.orders.maximum(:created_at)
      [ customer.updated_at, last_order_at ].compact.max < cutoff
    end

    def apply_action(record, action)
      case action
      when "archive"
        return if record.deleted?

        record.destroy!
        record_applied_event(record, "automated_archive", action)
      when "anonymise"
        return if record.deleted?

        record.anonymise!
        record.destroy! unless record.deleted?
        record_applied_event(record, "automated_anonymise_archive", action)
      end
    end

    def held_for_retention?(record)
      record.respond_to?(:retention_hold_active?) && record.retention_hold_active?(reference_time: now)
    end

    def record_held_event(record, action)
      DataRetention::EventRecorder.record!(
        account: account,
        record: record,
        event_type: "held_record_skipped",
        action_name: action,
        details: held_details(record)
      )
    end

    def record_applied_event(record, event_type, action)
      DataRetention::EventRecorder.record!(
        account: account,
        record: record,
        event_type: event_type,
        action_name: action,
        details: "Automated retention action applied for inactivity policy."
      )
    end

    def held_details(record)
      details = [ "Retention hold active" ]
      details << "Hold until #{record.retention_hold_until}" if record.respond_to?(:retention_hold_until) && record.retention_hold_until.present?
      details << "Reason: #{record.retention_hold_reason}" if record.respond_to?(:retention_hold_reason) && record.retention_hold_reason.present?
      details.join(". ")
    end
  end
end
