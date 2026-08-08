module Noticed
  class Notification < ApplicationRecord
    include Rails.application.routes.url_helpers
    include Readable
    include Translation

    belongs_to :account, optional: true
    belongs_to :event, counter_cache: true
    belongs_to :recipient, polymorphic: true

    scope :newest_first, -> { order(created_at: :desc) }
    scope :for_account, ->(account) { joins(:event).where(noticed_events: { account_id: account.id }) }

    delegate :params, :record, to: :event
  end
end

ActiveSupport.run_load_hooks :noticed_notification, Noticed::Notification
