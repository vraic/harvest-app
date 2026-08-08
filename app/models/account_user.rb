class AccountUser < ApplicationRecord
  has_prefix_id :au
  acts_as_tenant :account
  belongs_to :user

  enum :user_role, { store_manager: 0, store_staff: 1, customer: 2 }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :staff, -> { where(user_role: [ :store_manager, :store_staff ]) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end
end
