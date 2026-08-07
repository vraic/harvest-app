class LoyaltyProgram < ApplicationRecord
  acts_as_tenant :account
  audited associated_with: :account
  has_prefix_id :lp

  belongs_to :account
  has_many :loyalty_cards, dependent: :destroy
  has_many :customers, through: :loyalty_cards

  validates :points_to_currency_ratio, presence: true, numericality: { greater_than: 0 }
  validates :currency_to_points_ratio, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def points_to_currency(points)
    (points * points_to_currency_ratio).to_f
  end

  def currency_to_points(amount)
    (amount * currency_to_points_ratio).to_i
  end
end
