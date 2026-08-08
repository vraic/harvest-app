class SupportRequest < ApplicationRecord
  BUSINESS_OVERRIDE_COLUMNS = %w[
    received_outside_system
    authorization_received_outside_system
    received_outside_system_confirmed_at
    received_outside_system_confirmed_by_id
  ].freeze

  audited associated_with: :account
  acts_as_tenant :account

  belongs_to :account
  belongs_to :requester, class_name: "User"
  belongs_to :received_outside_system_confirmed_by, class_name: "User", optional: true
  has_many :comments, class_name: "SupportRequestComment", dependent: :destroy

  attr_accessor :business_override, :business_override_confirmation

  enum :status, { pending: 0, accepted: 1, rejected: 2, closed: 3, extension_requested: 4 }, default: :pending

  validates :message, presence: true
  validate :business_override_confirmation_required, on: :create
  validate :business_override_columns_available, on: :create

  scope :active, -> { accepted.where("expires_at > ?", Time.current) }

  def active?
    accepted? && expires_at.present? && expires_at > Time.current
  end

  def grant_authorization!
    update!(status: :accepted, expires_at: 72.hours.from_now)
  end

  def business_override?
    ActiveModel::Type::Boolean.new.cast(business_override)
  end

  def business_override_confirmation?
    ActiveModel::Type::Boolean.new.cast(business_override_confirmation)
  end

  def apply_business_override!(confirmed_by:)
    return unless self.class.business_override_columns_available?

    self.status = :accepted
    self.expires_at ||= 72.hours.from_now
    self.received_outside_system = true
    self.authorization_received_outside_system = true
    self.received_outside_system_confirmed_at = Time.current
    self.received_outside_system_confirmed_by = confirmed_by
  end

  def self.business_override_columns_available?
    (BUSINESS_OVERRIDE_COLUMNS - column_names).empty?
  end

  private

  def business_override_confirmation_required
    return unless business_override?
    return if business_override_confirmation?

    errors.add(:business_override_confirmation, "must be accepted to use business override")
  end

  def business_override_columns_available
    return unless business_override?
    return if self.class.business_override_columns_available?

    errors.add(:base, "Business override fields are unavailable. Please run database migrations.")
  end
end
