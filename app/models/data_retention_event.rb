class DataRetentionEvent < ApplicationRecord
  EVENT_TYPES = %w[
    automated_archive
    automated_anonymise_archive
    automated_purge
    held_record_skipped
    manual_hold_enabled
    manual_hold_disabled
  ].freeze

  belongs_to :account
  belongs_to :actor, class_name: "User", optional: true

  validates :record_type, :record_id, :event_type, :action_name, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }

  scope :recent, -> { order(created_at: :desc) }
end