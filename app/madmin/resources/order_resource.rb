class OrderResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :status
  attribute :total_amount_cents
  attribute :currency
  attribute :notes
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :number
  attribute :loyalty_points_redeemed
  attribute :loyalty_discount_amount_cents

  # Associations
  attribute :audits
  attribute :account
  attribute :customer
  attribute :location
  attribute :user
  attribute :order_items
  attribute :payment
  attribute :staff_notes
  attribute :loyalty_transactions

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
