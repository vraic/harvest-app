class InventoryGroup < ApplicationRecord
  acts_as_tenant :account
  has_prefix_id :igrp

  has_many :inventory_items, dependent: :nullify
  has_one_attached :image
  has_many :inventory_group_suppliers, dependent: :destroy
  has_many :suppliers, through: :inventory_group_suppliers
  has_many :inventory_group_customers, dependent: :destroy
  has_many :customers, through: :inventory_group_customers

  validates :name, presence: true

  def visible_to?(partner)
    case partner
    when Supplier
      return true if suppliers.empty?
      suppliers.include?(partner)
    when Customer
      return true if customers.empty?
      customers.include?(partner)
    else
      false
    end
  end
end
