class InventoryItemResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :description
  attribute :price_cents
  attribute :price_currency
  attribute :unit_type
  attribute :weight_value
  attribute :weight_unit
  attribute :deleted_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :warn_when_low_on_stock
  attribute :low_stock_threshold
  attribute :image, index: false

  # Associations
  attribute :audits
  attribute :account
  attribute :inventory_group
  attribute :parent
  attribute :variants
  attribute :inventory_levels
  attribute :locations
  attribute :order_items
  attribute :supplier_prices

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Add actions to the resource's index page
  # collection_action do
  #   link_to "Bulk Import", bulk_import_path, class: "btn btn-secondary"
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
