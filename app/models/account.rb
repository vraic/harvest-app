class Account < ApplicationRecord
  has_referrals
  has_one_attached :header_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :card, resize_to_limit: [ 600, 400 ]
  end
  audited
  has_associated_audits
  has_prefix_id :acct
  has_many :account_users
  has_many :customers
  has_many :suppliers
  has_many :sent_supplier_requests, class_name: "SupplierRequest", foreign_key: "sender_account_id", dependent: :destroy
  has_many :received_supplier_requests, class_name: "SupplierRequest", foreign_key: "receiver_account_id", dependent: :destroy
  has_many :users, through: :account_users
  has_many :notes, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :inventory_groups, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :support_requests, dependent: :destroy
  has_one :loyalty_program, dependent: :destroy
  accepts_nested_attributes_for :loyalty_program
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"

  enum :gocardless_mode, { sandbox: 0, production: 1 }
  encrypts :gocardless_access_token

  validates :name, presence: true
  validates :owner_id, presence: true
  validates :gocardless_access_token, length: { minimum: 8 }, allow_blank: true

  scope :b2c, -> { where(is_b2c: true) }
  scope :b2b, -> { where(is_b2b: true) }
  scope :internal, -> { where(is_internal: true) }

  after_create :create_default_referral_code
  after_create :assign_owner_as_manager

  def default_referral_code
    name.downcase.gsub(/[^a-z0-9]/, "")
  end

  private

  def assign_owner_as_manager
    ActsAsTenant.without_tenant do
      AccountUser.unscoped.where(account_id: id, user_id: owner_id).first_or_create!(user_role: :store_manager)
    end
  end

  def create_default_referral_code
    referral_codes.create(code: default_referral_code)
  end

  def cleanup_side_effects
    Customer.unscoped.where(account_id: id).delete_all!
    AccountUser.unscoped.where(account_id: id).delete_all
  end
end
