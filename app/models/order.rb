class Order < ApplicationRecord
  audited associated_with: :account
  include SearchCop
  acts_as_tenant :account
  has_prefix_id :order

  search_scope :search do
    attributes :id, :total_amount_cents, :number
    # Use exact match for encrypted fields as deterministic encryption does not support LIKE
    attributes customer: "customer.name"
  end

  belongs_to :customer
  belongs_to :location, optional: true
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_one :payment, dependent: :destroy
  has_many :staff_notes, as: :notable, class_name: "Note", dependent: :destroy
  has_many :loyalty_transactions, dependent: :nullify

  accepts_nested_attributes_for :order_items, allow_destroy: true

  monetize :total_amount_cents

  enum :status, { ordered: 0, awaiting_collection: 1, complete: 2 }

  validates :status, presence: true
  validates :number, presence: true, uniqueness: true
  validates :location_id, presence: true, if: :customer_order?

  before_validation :generate_number, on: :create
  before_validation :calculate_total
  before_validation :sync_item_locations
  after_create :process_loyalty_redemption
  after_create :send_received_email
  after_update :process_loyalty_accrual, if: -> { saved_change_to_status? && complete? }
  after_update :send_status_emails, if: :saved_change_to_status?

  def loyalty_discount
    Money.new(loyalty_discount_amount_cents, Money.default_currency)
  end

  def customer_order?
    user.nil?
  end

  private

  def sync_item_locations
    return unless location_id

    order_items.each do |item|
      item.location_id = location_id if item.location_id.blank? || customer_order?
    end
  end

  def process_loyalty_accrual
    return unless account.loyalty_program&.active?
    return if loyalty_transactions.accrual.exists? # Prevent double accrual

    card = customer.loyalty_card || customer.create_loyalty_card(loyalty_program: account.loyalty_program)
    points = account.loyalty_program.currency_to_points(total_amount.to_f)
    card.add_points!(points, self) if points > 0
  end

  def process_loyalty_redemption
    return unless loyalty_points_redeemed > 0
    customer.loyalty_card.redeem_points!(loyalty_points_redeemed, self)
  end

  def generate_number
    return if number.present?

    self.number = loop do
      random_number = Array.new(3) { rand(1..9) }.join + Array.new(3) { ("A".."Z").to_a.sample }.join
      break random_number unless Order.exists?(number: random_number)
    end
  end

  def calculate_total
    order_items.each { |item| item.set_default_price if item.new_record? }
    base_total_cents = order_items.reject(&:marked_for_destruction?).sum { |item| item.price_cents * item.quantity }

    if loyalty_points_redeemed > 0 && customer&.loyalty_card && account.loyalty_program&.active?
      program = account.loyalty_program
      # Ensure they have enough points
      points = [ loyalty_points_redeemed, customer.loyalty_card.points_balance ].min
      self.loyalty_points_redeemed = points
      self.loyalty_discount_amount_cents = (program.points_to_currency(points) * 100).to_i
    else
      self.loyalty_discount_amount_cents = 0
    end

    self.total_amount_cents = [ base_total_cents - loyalty_discount_amount_cents, 0 ].max
  end

  def send_received_email
    OrderMailer.order_received(self).deliver_later
  end

  def send_status_emails
    if awaiting_collection?
      OrderMailer.order_awaiting_collection(self).deliver_later
    end
  end
end
