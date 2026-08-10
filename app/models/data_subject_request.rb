class DataSubjectRequest < ApplicationRecord
  LAWFUL_BASES = {
    "consent" => "Consent",
    "contract" => "Contract",
    "legal_obligation" => "Legal obligation",
    "vital_interests" => "Vital interests",
    "public_task" => "Public task",
    "legitimate_interests" => "Legitimate interests"
  }.freeze

  audited associated_with: :account
  acts_as_tenant :account

  encrypts :subject_name, :subject_email, deterministic: true
  has_many_attached :evidence_files

  belongs_to :account
  belongs_to :requester, class_name: "User"
  belongs_to :subject_user, class_name: "User", optional: true
  belongs_to :acted_by, class_name: "User", optional: true

  enum :request_type, {
    access: 0,
    rectification: 1,
    erasure: 2,
    restriction: 3,
    objection: 4,
    portability: 5
  }

  enum :status, {
    received: 0,
    identity_verification_pending: 1,
    in_review: 2,
    action_required: 3,
    completed: 4,
    rejected: 5
  }

  enum :offboarding_action, {
    none: 0,
    archive: 1,
    anonymise: 2,
    hard_delete: 3
  }, prefix: :offboarding

  validates :request_type, :status, :requested_at, :due_on, :request_summary, presence: true
  validates :legal_basis, inclusion: { in: LAWFUL_BASES.keys }, allow_blank: true
  validates :decision_summary, presence: true, if: :completed_or_rejected?
  validates :completed_at, presence: true, if: :completed?
  validates :subject_user, presence: true, if: :offboarding_action_required?
  validate :subject_user_belongs_to_account, if: :validate_subject_user_account_membership?

  scope :open_requests, -> { where.not(status: [ :completed, :rejected ]) }
  scope :overdue, -> { open_requests.where("due_on < ?", Date.current) }

  before_validation :set_defaults
  before_validation :verify_identity_for_in_app_request
  before_validation :hydrate_subject_details

  def completed_or_rejected?
    completed? || rejected?
  end

  def offboarding_action_required?
    erasure? && !offboarding_none?
  end

  def mark_completed!(actor:)
    transaction do
      self.status = :completed
      self.completed_at ||= Time.current
      self.acted_by = actor
      self.acted_at = Time.current
      save!

      apply_offboarding_action!(actor: actor) if offboarding_action_required?
    end
  end

  def apply_offboarding_action!(actor:)
    return unless offboarding_action_required?

    subject = User.with_deleted.find_by(id: subject_user_id)
    raise ArgumentError, "Subject user was not found" if subject.nil?

    with_subject_tenant(subject) do
      case offboarding_action
      when "archive"
        subject.destroy! unless subject.deleted?
      when "anonymise"
        subject.anonymise!
        subject.destroy! unless subject.deleted?
      when "hard_delete"
        raise ArgumentError, "Hard delete requires an admin actor" unless actor&.admin?
        subject.destroy_fully!
      end
    end

    self.acted_by = actor
    self.acted_at = Time.current
    save! if changed?
  end

  def self.lawful_basis_options_for_select
    LAWFUL_BASES.map { |value, label| [ label, value ] }
  end

  private

  def set_defaults
    self.status ||= :received
    self.offboarding_action ||= :none
    self.requested_at ||= Time.current
    self.due_on ||= requested_at.to_date + default_due_days.days
  end

  def hydrate_subject_details
    return unless subject_user.present?

    self.subject_name ||= subject_user.name
    self.subject_email ||= subject_user.email_address
  end

  def verify_identity_for_in_app_request
    self.identity_verified = true if requester_id.present?
  end

  def default_due_days
    Rails.application.config.x.data_protection.data_subject_request_due_days.presence || 30
  end

  def with_subject_tenant(subject)
    tenant_account = subject_account(subject) || account

    if tenant_account.present?
      ActsAsTenant.with_tenant(tenant_account) { yield }
    else
      yield
    end
  end

  def subject_account(subject)
    AccountUser.unscoped.where(user_id: subject.id).includes(:account).first&.account ||
      Customer.with_deleted.find_by(user_id: subject.id)&.account
  end

  def subject_user_belongs_to_account
    return if AccountUser.unscoped.exists?(account_id: account_id, user_id: subject_user_id)

    errors.add(:subject_user, :invalid)
  end

  def validate_subject_user_account_membership?
    subject_user_id.present? &&
      account_id.present? &&
      (new_record? || will_save_change_to_subject_user_id? || will_save_change_to_account_id?)
  end
end
