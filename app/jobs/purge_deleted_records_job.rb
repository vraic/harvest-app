class PurgeDeletedRecordsJob < ApplicationJob
  queue_as :default

  def perform(retention_days: nil)
    retention_days ||= Rails.application.config.x.data_protection.soft_delete_retention_days
    cutoff = retention_days.days.ago

    ActsAsTenant.without_tenant do
      purge_records(User, cutoff)
      purge_records(Customer, cutoff)
      purge_records(Supplier, cutoff)
    end
  end

  private

  def purge_records(model, cutoff)
    model.only_deleted.where("deleted_at < ?", cutoff).find_each do |record|
      tenant_account = account_for(record)

      begin
        if tenant_account.present?
          ActsAsTenant.with_tenant(tenant_account) { record.destroy_fully! }
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
    when User
      AccountUser.unscoped.where(user_id: record.id).includes(:account).first&.account ||
        Customer.with_deleted.find_by(user_id: record.id)&.account
    when Customer, Supplier
      Account.unscoped.find_by(id: record.account_id)
    end
  end
end
