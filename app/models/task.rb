class Task < ApplicationRecord
  audited associated_with: :account
  acts_as_tenant :account
  has_prefix_id :task

  belongs_to :account
  belongs_to :responsible_user, class_name: "User", optional: true
  belongs_to :assigned_by, class_name: "User"

  has_many_attached :attachments

  validates :title, presence: true

  scope :completed, -> { where.not(completed_at: nil) }
  scope :incomplete, -> { where(completed_at: nil) }

  after_commit :notify_assignment_change, on: [ :create, :update ]

  def completed?
    completed_at.present?
  end

  def complete!
    update!(completed_at: Time.current)
  end

  def incomplete!
    update!(completed_at: nil)
  end

  private

  def notify_assignment_change
    return unless saved_change_to_responsible_user_id? || saved_change_to_id?

    recipients = if responsible_user.present?
      [ responsible_user ]
    else
      account.active_staff_users
    end

    return if recipients.empty?

    TaskAssignedNotifier.with(record: self, account_id: account_id).deliver(recipients)
  end

  broadcasts_to ->(task) { [ task.account, "tasks" ] }, inserts_by: :prepend
end
