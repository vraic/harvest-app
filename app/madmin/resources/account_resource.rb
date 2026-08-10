class AccountResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :address
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :is_b2c
  attribute :is_b2b
  attribute :is_internal
  attribute :gocardless_access_token
  attribute :gocardless_mode
  attribute :inactivity_retention_years_override
  attribute :soft_delete_retention_days_override
  attribute :inactive_customer_retention_action
  attribute :inactive_supplier_retention_action
  attribute :header_image, index: false

  # Associations
  attribute :referral_codes
  attribute :referrals
  attribute :referral
  attribute :audits
  attribute :associated_audits
  attribute :account_users
  attribute :customers
  attribute :suppliers
  attribute :sent_supplier_requests
  attribute :received_supplier_requests
  attribute :users
  attribute :notes
  attribute :orders
  attribute :inventory_items
  attribute :inventory_groups
  attribute :locations
  attribute :tasks
  attribute :support_requests
  attribute :data_retention_events
  attribute :loyalty_program
  attribute :noticed_events
  attribute :noticed_notifications
  attribute :owner

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
