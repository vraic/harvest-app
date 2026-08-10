class CustomerResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :email_address
  attribute :phone
  attribute :deleted_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :subscribed_to_newsletter
  attribute :subscribed_at
  attribute :gocardless_customer_id
  attribute :gocardless_mandate_id
  attribute :gocardless_configured_at
  attribute :retention_hold
  attribute :retention_hold_until
  attribute :retention_hold_reason

  # Associations
  attribute :audits
  attribute :account
  attribute :user
  attribute :customer_account
  attribute :orders
  attribute :payments
  attribute :inventory_group_customers
  attribute :inventory_groups
  attribute :loyalty_card

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
