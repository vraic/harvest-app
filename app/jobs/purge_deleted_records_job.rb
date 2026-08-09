class PurgeDeletedRecordsJob < ApplicationJob
  queue_as :default

  def perform(retention_days: nil)
    default_retention_days = retention_days || Rails.application.config.x.data_protection.soft_delete_retention_days
    user_cutoff = default_retention_days.days.ago

    ActsAsTenant.without_tenant do
      Account.find_each do |account|
        policy = DataRetention::Policy.new(account)

        ActsAsTenant.with_tenant(account) do
          DataRetention::Watcher.new(account: account, policy: policy).run

          purge_records(Customer, policy.soft_delete_cutoff_time, account: account)
          purge_records(Supplier, policy.soft_delete_cutoff_time, account: account)
        end
      end

      purge_records(User, user_cutoff)
    end
  end

  private

  def purge_records(model, cutoff, account: nil)
    scope = model.only_deleted.where("deleted_at < ?", cutoff)
    scope = scope.where(account_id: account.id) if account.present? && model.column_names.include?("account_id")

    scope.find_each do |record|
      tenant_account = account_for(record)

      begin
        if retention_hold_active?(record)
          record_held_event(record, tenant_account)
          next
        end

        if tenant_account.present?
          ActsAsTenant.with_tenant(tenant_account) { record.destroy_fully! }
          record_purged_event(record, tenant_account)
        else
          record.destroy_fully!
        end
      rescue ActiveRecord::InvalidForeignKey => e
        Rails.logger.warn("Skipping purge for #{model.name}##{record.id}: #{e.message}")
      end
    end
  end

  def account_for(record)
    case record
    when Customer, Supplier
      Account.unscoped.find_by(id: record.account_id)
    when User
      AccountUser.unscoped.where(user_id: record.id).includes(:account).first&.account ||
        Customer.with_deleted.find_by(user_id: record.id)&.account
    end
  end

  def retention_hold_active?(record)
    record.respond_to?(:retention_hold_active?) && record.retention_hold_active?
  end

  def record_held_event(record, account)
    return if account.blank?

    DataRetention::EventRecorder.record!(
      account:,
      record:,
      event_type: "held_record_skipped",
      action_name: "purge",
      details: held_details(record)
    )
  end

  def record_purged_event(record, account)
    DataRetention::EventRecorder.record!(
      account:,
      record:,
      event_type: "automated_purge",
      action_name: "purge",
      details: "Record permanently deleted by retention purge."
    )
  end

  def held_details(record)
    details = [ "Retention hold active" ]
    details << "Hold until #{record.retention_hold_until}" if record.respond_to?(:retention_hold_until) && record.retention_hold_until.present?
    details << "Reason: #{record.retention_hold_reason}" if record.respond_to?(:retention_hold_reason) && record.retention_hold_reason.present?
    details.join(". ")
  end
end
