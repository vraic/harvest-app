class Supplier < ApplicationRecord
  audited associated_with: :account
  include SearchCop
  include Anony::Anonymisable
  acts_as_paranoid
  acts_as_tenant :account
  has_prefix_id :supp
  encrypts :name, :email_address, deterministic: true

  search_scope :search do
    attributes :name, :email_address, :phone
    attributes supplier_account: "supplier_account.name"
  end

  belongs_to :supplier_account, class_name: "Account", optional: true
  belongs_to :user, optional: true
  has_many :inventory_group_suppliers, dependent: :destroy
  has_many :inventory_groups, through: :inventory_group_suppliers
  has_many :supplier_prices, dependent: :destroy

  before_validation :link_by_email
  before_save :set_subscribed_at, if: :will_save_change_to_subscribed_to_newsletter?
  after_save :sync_email_to_user, if: :saved_change_to_email_address?

  anonymise do
    overwrite do
      ignore :account_id, :supplier_account_id, :user_id, :subscribed_to_newsletter, :subscribed_at,
             :retention_hold, :retention_hold_until, :retention_hold_reason
      hex :name
      email :email_address
      hex :phone
    end
  end

  validates :name, presence: true
  validates :retention_hold_reason, length: { maximum: 255 }, allow_blank: true
  validate :retention_hold_until_must_be_today_or_later, if: :retention_hold?

  before_validation :clear_retention_hold_fields_unless_held

  def inventory_items
    return InventoryItem.none unless supplier_account

    # Find the Customer record in the supplier_account that represents the current account
    customer = supplier_account.customers.find_by(customer_account_id: account_id)
    return InventoryItem.none unless customer

    # Find items in supplier_account's groups that are visible to this customer
    # Or groups that have NO specific visibility (visible to all)
    InventoryItem.unscoped.where(account_id: supplier_account_id)
                 .joins(:inventory_group)
                 .where(inventory_groups: { id: InventoryGroup.unscoped.where(account_id: supplier_account_id)
                                                                .left_outer_joins(:customers)
                                                                .where("customers.id IS NULL OR customers.id = ?", customer.id)
                                                                .select(:id) })
  end

  def retention_hold_active?(reference_time: Time.current)
    return false unless retention_hold?
    return true if retention_hold_until.blank?

    retention_hold_until >= reference_time.to_date
  end

  private

  def clear_retention_hold_fields_unless_held
    return if retention_hold?

    self.retention_hold_until = nil
    self.retention_hold_reason = nil
  end

  def retention_hold_until_must_be_today_or_later
    return if retention_hold_until.blank?
    return unless retention_hold_until < Date.current

    errors.add(:retention_hold_until, "must be today or later")
  end

  def link_by_email
    if email_address.present?
      # Link User
      self.user ||= User.find_by(email_address: email_address)

      # Link Account
      if supplier_account.nil? && user.present?
        # Use unscoped to find account users across all tenants
        target_account_users = AccountUser.unscoped.where(user_id: user.id)
        # Try to find account where they are owner
        account = Account.where(owner_id: user.id).first
        # Fallback to any account they belong to
        account ||= Account.where(id: target_account_users.select(:account_id)).first
        self.supplier_account = account
      end
    end
  end

  def sync_email_to_user
    user&.update(email_address: email_address) if user&.email_address != email_address
  end

  def set_subscribed_at
    if subscribed_to_newsletter?
      self.subscribed_at = Time.current
    else
      self.subscribed_at = nil
    end
  end
end
