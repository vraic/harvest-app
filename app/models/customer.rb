class Customer < ApplicationRecord
  audited associated_with: :account
  include SearchCop
  include Anony::Anonymisable
  acts_as_paranoid
  acts_as_tenant :account
  has_prefix_id :cust
  encrypts :name, :email_address, deterministic: true

  search_scope :search do
    attributes :name, :email_address, :phone
    attributes customer_account: "customer_account.name"
  end

  belongs_to :user, optional: true
  belongs_to :customer_account, class_name: "Account", optional: true
  has_many :orders, dependent: :destroy
  has_many :payments, dependent: :nullify
  has_many :inventory_group_customers, dependent: :destroy
  has_many :inventory_groups, through: :inventory_group_customers
  has_one :loyalty_card, dependent: :destroy

  before_validation :link_by_email
  before_save :set_subscribed_at, if: :will_save_change_to_subscribed_to_newsletter?
  after_save :sync_email_to_user, if: :saved_change_to_email_address?
  after_save :ensure_account_user, if: -> { saved_change_to_user_id? && user_id.present? }

  anonymise do
    overwrite do
      ignore :account_id, :user_id, :customer_account_id, :subscribed_to_newsletter, :subscribed_at,
             :gocardless_customer_id, :gocardless_mandate_id, :gocardless_configured_at
      hex :name
      email :email_address
      hex :phone
    end
  end

  validates :name, presence: true

  def gocardless_configured?
    gocardless_customer_id.present? && gocardless_mandate_id.present?
  end

  private

  def link_by_email
    if email_address.present?
      # Link User
      self.user ||= User.find_by(email_address: email_address)

      # Link Account
      if customer_account.nil? && user.present?
        # Use unscoped to find account users across all tenants
        target_account_users = AccountUser.unscoped.where(user_id: user.id, user_role: [ :store_manager, :store_staff ])
        # Try to find account where they are owner
        account = Account.where(owner_id: user.id).first
        # Fallback to any account they manage
        account ||= Account.where(id: target_account_users.select(:account_id)).first
        self.customer_account = account
      end
    end
  end

  def sync_email_to_user
    user&.update(email_address: email_address) if user&.email_address != email_address
  end

  def ensure_account_user
    return unless user_id && account_id
    # We use unscoped here to find/create AccountUser across any existing tenant context
    # Wrapping in without_tenant ensures ActsAsTenant doesn't overwrite account_id if Current.account is set
    ActsAsTenant.without_tenant do
      AccountUser.unscoped.where(account_id: account_id, user_id: user_id).first_or_create!(user_role: :customer)
    end
  end

  private

  def set_subscribed_at
    if subscribed_to_newsletter?
      self.subscribed_at = Time.current
    else
      self.subscribed_at = nil
    end
  end
end
