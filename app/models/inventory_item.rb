class InventoryItem < ApplicationRecord
  audited associated_with: :account
  include SearchCop
  acts_as_tenant :account
  acts_as_paranoid
  has_prefix_id :item

  search_scope :search do
    attributes :name, :description, :weight_value, :weight_unit
    attributes weight: [ :weight_value, :weight_unit ]
    attributes inventory_group: "inventory_group.name"
  end

  belongs_to :inventory_group, optional: true
  has_one_attached :image
  belongs_to :parent, class_name: "InventoryItem", optional: true
  has_many :variants, class_name: "InventoryItem", foreign_key: "parent_id", dependent: :destroy
  has_many :inventory_levels, dependent: :destroy
  has_many :locations, through: :inventory_levels
  has_many :order_items, dependent: :delete_all
  has_many :supplier_prices, dependent: :destroy

  monetize :price_cents, allow_nil: true

  enum :unit_type, { per_unit: 0, per_weight: 1 }

  validates :name, presence: true
  validates :weight_value, presence: true, if: :per_weight?
  validates :weight_unit, presence: true, if: :per_weight?

  scope :low_stock, -> {
    left_outer_joins(:inventory_levels)
    .where(warn_when_low_on_stock: true)
    .group(:id)
    .having("COALESCE(SUM(inventory_levels.quantity), 0) <= low_stock_threshold")
  }

  def display_name
    if parent
      "#{parent.name} - #{variant_label}"
    else
      name
    end
  end

  def variant_label
    return name unless per_weight?

    formatted_weight = weight_value.to_s.gsub(/\.0\z/, "")

    if name == parent&.name || name.blank?
      "#{formatted_weight}#{weight_unit}"
    else
      "#{name} (#{formatted_weight}#{weight_unit})"
    end
  end

  def price
    inherited_price = super
    return inherited_price if inherited_price.present? || parent.nil?

    parent.price
  end

  def price_for(supplier)
    supplier_price = supplier_prices.find_by(supplier: supplier)
    return supplier_price.price if supplier_price

    price
  end

  def total_quantity
    inventory_levels.sum(:quantity)
  end

  def stock_unit
    weight_unit.presence || "unit"
  end

  def stock_by_location
    inventory_levels.pluck(:location_id, :quantity).to_h
  end

  def stock_data
    {
      price: price.to_f,
      total: total_quantity,
      locations: stock_by_location
    }
  end
end
