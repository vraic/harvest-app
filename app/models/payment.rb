class Payment < ApplicationRecord
  audited associated_with: :account
  acts_as_tenant :account

  belongs_to :order
  belongs_to :customer

  enum :payment_method, { cash_on_collection: 0, gocardless: 1 }
  enum :status, { pending: 0, paid: 1, failed: 2 }

  monetize :amount_cents

  validates :payment_method, :status, :amount_cents, :currency, presence: true
  validates :provider_reference, presence: true, if: :gocardless?
end
